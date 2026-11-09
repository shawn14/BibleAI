//
//  HighlightService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

class HighlightService: ObservableObject {
    static let shared = HighlightService()

    @Published var highlights: [Highlight] = []


    private init() {
        loadHighlights()
        NotificationCenter.default.addObserver(forName: CloudSync.didChange, object: nil, queue: .main) { [weak self] _ in
            self?.loadHighlights()
        }
    }

    // MARK: - Persistence

    private func loadHighlights() {
        let keys: [CloudSync.Key] = [.highlights, .editionHighlights]
        highlights = keys.flatMap { key -> [Highlight] in
            guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { return [] }
            return (try? JSONDecoder().decode([Highlight].self, from: data)) ?? []
        }.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveHighlights(edition: String) {
        // Older app versions assume everything in the original key is quoted from KJV.
        let key: CloudSync.Key = edition == "KJV" ? .highlights : .editionHighlights
        let records = highlights.filter { ($0.citationEdition == "KJV") == (key == .highlights) }
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(encoded, forKey: key.rawValue)
        CloudSync.shared.push(key)
    }

    // MARK: - Highlight Management

    func addHighlight(book: String, chapter: Int, verse: Int, verseText: String, translation: String = "KJV", color: HighlightColor, note: String? = nil) {
        // Check if already highlighted
        if let existing = getHighlight(book: book, chapter: chapter, verse: verse, translation: translation) {
            // Update existing highlight
            updateHighlight(id: existing.id, color: color, note: note)
            return
        }

        let highlight = Highlight(
            book: book,
            chapter: chapter,
            verse: verse,
            verseText: verseText,
            translation: translation,
            color: color,
            note: note
        )

        highlights.insert(highlight, at: 0)
        saveHighlights(edition: translation)
    }

    func removeHighlight(id: UUID) {
        guard let removed = highlights.first(where: { $0.id == id }) else { return }
        CloudSync.shared.recordDeletion(.highlightsDeleted, id: CloudSyncMerge.verseKey(removed))
        highlights.removeAll { $0.id == id }
        saveHighlights(edition: removed.citationEdition)
    }

    func updateHighlight(id: UUID, color: HighlightColor? = nil, note: String? = nil) {
        guard let index = highlights.firstIndex(where: { $0.id == id }) else { return }

        var updated = highlights[index]
        if let color = color {
            updated = Highlight(
                id: updated.id,
                book: updated.book,
                chapter: updated.chapter,
                verse: updated.verse,
                verseText: updated.verseText,
                translation: updated.translation,
                color: color,
                note: note ?? updated.note,
                createdAt: updated.createdAt,
                updatedAt: Date()
            )
        } else if note != nil {
            updated = Highlight(
                id: updated.id,
                book: updated.book,
                chapter: updated.chapter,
                verse: updated.verse,
                verseText: updated.verseText,
                translation: updated.translation,
                color: updated.color,
                note: note,
                createdAt: updated.createdAt,
                updatedAt: Date()
            )
        }

        highlights[index] = updated
        saveHighlights(edition: updated.citationEdition)
    }

    func getHighlight(book: String, chapter: Int, verse: Int, translation: String = "KJV") -> Highlight? {
        highlights.first { $0.book == book && $0.chapter == chapter && $0.verse == verse && $0.citationEdition == translation }
    }

    func getHighlights(for book: String? = nil, chapter: Int? = nil) -> [Highlight] {
        var filtered = highlights

        if let book = book {
            filtered = filtered.filter { $0.book == book }
        }

        if let chapter = chapter {
            filtered = filtered.filter { $0.chapter == chapter }
        }

        return filtered
    }

    // MARK: - Statistics

    var totalHighlights: Int {
        highlights.count
    }

    var highlightsByBook: [String: Int] {
        Dictionary(grouping: highlights, by: { $0.book })
            .mapValues { $0.count }
    }

    var highlightsByColor: [HighlightColor: Int] {
        Dictionary(grouping: highlights, by: { $0.color })
            .mapValues { $0.count }
    }
}
