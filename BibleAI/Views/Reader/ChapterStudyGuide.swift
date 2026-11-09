import SwiftUI

private struct ChapterGuideEntry: Decodable {
    let focus: StudyPassage
    let title: String
    let explanation: String
    let related: StudyPassage
    let reflection: String

    var body: String {
        "\(explanation) (\(focus.reference)).\n\nRead alongside \(related.reference). \(reflection)"
    }
}

enum GospelTourGuide {
    private static let entries: [ChapterGuideEntry] = {
        guard let url = Bundle.main.url(forResource: "GospelTourGuides", withExtension: "json") else {
            NSLog("Gospel Tour guide resource missing")
            return []
        }
        do {
            return try JSONDecoder().decode([ChapterGuideEntry].self, from: Data(contentsOf: url))
        } catch {
            NSLog("Gospel Tour guides unavailable: %@", error.localizedDescription)
            return []
        }
    }()

    private static func entry(for verse: BibleVerse) -> ChapterGuideEntry? {
        entries.first { $0.focus.book == verse.book && $0.focus.chapter == verse.chapter }
    }

    static func study(for verse: BibleVerse) -> SavedStudy? {
        guard let entry = entry(for: verse) else { return nil }
        return SavedStudy(verse: verse, source: .guide, title: entry.title, body: entry.body,
                          relatedPassage: entry.related)
    }

    static func relatedPassage(for study: SavedStudy) -> StudyPassage? {
        guard study.source == .guide else { return nil }
        if let saved = study.relatedPassage { return saved }
        // Resolve a legacy link only if it belongs to the commentary the reader saved.
        guard let entry = entry(for: study.verse), entry.title == study.title, entry.body == study.body else { return nil }
        return entry.related
    }
}

struct StudySaveButton: View {
    let study: SavedStudy
    @ObservedObject private var library = StudyLibrary.shared
    @State private var error: String?

    var body: some View {
        let saved = library.studies.contains { $0.matches(study) }
        Button(saved ? "Study saved" : "Save study", systemImage: saved ? "bookmark.fill" : "bookmark") {
            do { try library.save(study); error = nil }
            catch { self.error = "Couldn’t save this study. Try again." }
        }
        .disabled(saved)
        .accessibilityIdentifier("study.save")
        if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
    }
}

struct StudyDetailView: View {
    let study: SavedStudy
    var canSave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(study.title).font(.title2.bold())
                Text(study.verse.text).font(.system(.title3, design: .serif))
                Text(study.verse.fullReference).foregroundStyle(.secondary)
                Divider()
                Text(study.body).textSelection(.enabled).lineSpacing(4)
                    .accessibilityIdentifier("study.body")
                Text(study.source.rawValue).font(.footnote).foregroundStyle(.secondary)
                if canSave { StudySaveButton(study: study) }
                if let related = GospelTourGuide.relatedPassage(for: study),
                   related.first > 0, related.last >= related.first,
                   let edition = ReaderEdition(rawValue: study.verse.translation),
                   let book = BibleBookInfo.allBooks.first(where: { $0.name == related.book }),
                   (1...book.chapterCount).contains(related.chapter) {
                    NavigationLink {
                        ChapterReadingView(book: book, chapter: related.chapter, edition: edition,
                                           verseRange: related.first...related.last)
                    } label: {
                        Label("Read \(related.reference)", systemImage: "book")
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("study.related")
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle(canSave ? "Reading guide" : "Saved study")
        .navigationBarTitleDisplayMode(.inline)
    }
}
