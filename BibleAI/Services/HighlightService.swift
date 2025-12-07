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

    private let highlightsKey = "saved_highlights"

    private init() {
        loadHighlights()
    }

    // MARK: - Persistence

    private func loadHighlights() {
        if let data = UserDefaults.standard.data(forKey: highlightsKey),
           let decoded = try? JSONDecoder().decode([Highlight].self, from: data) {
            highlights = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func saveHighlights() {
        if let encoded = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(encoded, forKey: highlightsKey)
        }
    }

    // MARK: - Highlight Management

    func addHighlight(book: String, chapter: Int, verse: Int, verseText: String, color: HighlightColor, note: String? = nil) {
        // Check if already highlighted
        if let existing = getHighlight(book: book, chapter: chapter, verse: verse) {
            // Update existing highlight
            updateHighlight(id: existing.id, color: color, note: note)
            return
        }

        let highlight = Highlight(
            book: book,
            chapter: chapter,
            verse: verse,
            verseText: verseText,
            color: color,
            note: note
        )

        highlights.insert(highlight, at: 0)
        saveHighlights()
    }

    func removeHighlight(id: UUID) {
        highlights.removeAll { $0.id == id }
        saveHighlights()
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
                color: updated.color,
                note: note,
                createdAt: updated.createdAt,
                updatedAt: Date()
            )
        }

        highlights[index] = updated
        saveHighlights()
    }

    func getHighlight(book: String, chapter: Int, verse: Int) -> Highlight? {
        highlights.first { $0.book == book && $0.chapter == chapter && $0.verse == verse }
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
