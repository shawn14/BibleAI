import Foundation
import Combine

extension BibleVerse {
    var place: ReadingPlace { ReadingPlace(book: book, chapter: chapter, verse: verse) }
    var passageID: String { place.id }
}

/// One chapter at a time; the complete Bible never rides the app's launch path.
actor ScriptureChapterStore {
    static let shared = ScriptureChapterStore()
    private let directory: URL

    init() {
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Scripture/KJV", isDirectory: true)
    }

    /// The provider breaks some verses across lines ("darkness\nwas\nupon"); show each verse as one sentence.
    static func clean(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    func chapter(book: String, number: Int) async throws -> [BibleVerse] {
        guard let info = BibleBookInfo.allBooks.first(where: { $0.name == book }),
              (1...info.chapterCount).contains(number) else { throw ScriptureError.invalidPassage }
        let cache = directory.appendingPathComponent("\(info.abbreviation)-\(number).json")
        if let data = try? Data(contentsOf: cache),
           let verses = try? JSONDecoder().decode([BibleVerse].self, from: data),
           valid(verses, book: book, chapter: number) {
            return verses.map { BibleVerse(book: $0.book, chapter: $0.chapter, verse: $0.verse,
                                           text: Self.clean($0.text), translation: $0.translation) }
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "bible-api.com"
        components.path = "/\(book) \(number)"
        components.queryItems = [URLQueryItem(name: "translation", value: "kjv")]
        guard let url = components.url else { throw ScriptureError.invalidPassage }
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 20))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ScriptureError.unavailable
        }
        let result = try JSONDecoder().decode(BibleAPIResponse.self, from: data)
        guard result.translation_id == "kjv" else { throw ScriptureError.unavailable }
        let verses = result.verses.map {
            BibleVerse(book: book, chapter: $0.chapter, verse: $0.verse,
                       text: Self.clean($0.text), translation: "KJV")
        }
        guard valid(verses, book: book, chapter: number) else { throw ScriptureError.unavailable }
        // A cache is optional; a failed cache write must not prevent reading downloaded Scripture.
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(verses).write(to: cache, options: .atomic)
        } catch { NSLog("Scripture cache unavailable: %@", error.localizedDescription) }
        return verses
    }

    private func valid(_ verses: [BibleVerse], book: String, chapter: Int) -> Bool {
        !verses.isEmpty && verses.enumerated().allSatisfy {
            $0.element.book == book && $0.element.chapter == chapter && $0.element.verse == $0.offset + 1
                && !$0.element.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

enum ScriptureError: LocalizedError {
    case invalidPassage, unavailable
    var errorDescription: String? {
        switch self {
        case .invalidPassage: return "That passage isn't in this Bible. Check the book, chapter, and verse."
        case .unavailable: return "This chapter couldn't be loaded. Check your connection and try again."
        }
    }
}

@MainActor
final class ScriptureFeedModel: ObservableObject {
    @Published private(set) var verses: [BibleVerse] = []
    @Published var visibleID: String?
    @Published private(set) var loading = false
    @Published private(set) var loadingNext = false
    @Published var error: String?
    @Published private(set) var nextError: String?
    private let defaults: UserDefaults
    private var generation = UUID()
    private let placeKey = "scripture.readingPlace.v1"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    var current: BibleVerse? { verses.first { $0.passageID == visibleID } ?? verses.first }

    func start() async {
        guard verses.isEmpty, !loading else { return }
        let saved = defaults.data(forKey: placeKey).flatMap { try? JSONDecoder().decode(ReadingPlace.self, from: $0) }
        _ = await open(saved ?? .beginning)
    }

    @discardableResult
    func open(_ place: ReadingPlace) async -> Bool {
        let request = UUID()
        generation = request
        loading = true
        error = nil
        nextError = nil
        defer { if generation == request { loading = false } }
        do {
            let result = try await ScriptureChapterStore.shared.chapter(book: place.book, number: place.chapter)
            guard generation == request else { return false }
            guard let selected = result.first(where: { $0.verse == place.verse }) else {
                throw ScriptureError.invalidPassage
            }
            verses = result
            visibleID = selected.passageID
            save(selected)
            return true
        } catch {
            guard generation == request else { return false }
            self.error = error.localizedDescription
            return false
        }
    }

    func didScroll() async {
        guard !loading, let verse = current else { return }
        save(verse)
        guard let index = verses.firstIndex(where: { $0.passageID == verse.passageID }),
              index >= verses.count - 4 else { return }
        await loadNext()
    }

    func loadNext() async {
        guard !loading, !loadingNext, let last = verses.last,
              let next = adjacentChapter(to: last.place, direction: 1) else { return }
        loadingNext = true
        nextError = nil
        let request = generation
        defer { loadingNext = false }
        do {
            let result = try await ScriptureChapterStore.shared.chapter(book: next.book, number: next.chapter)
            guard generation == request else { return }
            verses.append(contentsOf: result)
            // Keep at most three chapters in memory without removing the visible chapter.
            let groups = verses.reduce(into: [String]()) { keys, verse in
                let key = "\(verse.book)|\(verse.chapter)"
                if keys.last != key { keys.append(key) }
            }
            if groups.count > 3, let current = current {
                let currentKey = "\(current.book)|\(current.chapter)"
                let removable = groups.prefix(groups.count - 3).prefix { $0 != currentKey }
                verses.removeAll { removable.contains("\($0.book)|\($0.chapter)") }
            }
        } catch { if generation == request { nextError = error.localizedDescription } }
    }

    func previousChapter() async {
        if let current, let previous = adjacentChapter(to: current.place, direction: -1) { await open(previous) }
    }

    var hasPreviousChapter: Bool {
        current.flatMap { adjacentChapter(to: $0.place, direction: -1) } != nil
    }

    private func adjacentChapter(to place: ReadingPlace, direction: Int) -> ReadingPlace? {
        let books = BibleBookInfo.allBooks
        guard let index = books.firstIndex(where: { $0.name == place.book }) else { return nil }
        let chapter = place.chapter + direction
        if (1...books[index].chapterCount).contains(chapter) {
            return ReadingPlace(book: place.book, chapter: chapter, verse: 1)
        }
        let next = index + direction
        guard books.indices.contains(next) else { return nil }
        return ReadingPlace(book: books[next].name, chapter: direction > 0 ? 1 : books[next].chapterCount, verse: 1)
    }

    private func save(_ verse: BibleVerse) {
        if let data = try? JSONEncoder().encode(verse.place) {
            defaults.set(data, forKey: placeKey)
            if defaults === UserDefaults.standard { CloudSync.shared.push(.place) }
        }
    }
}
