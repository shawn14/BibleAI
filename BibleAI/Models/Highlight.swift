//
//  Highlight.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI

enum HighlightColor: String, Codable, CaseIterable {
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case orange = "orange"

    var color: Color {
        switch self {
        case .yellow:
            return Color.yellow.opacity(0.3)
        case .green:
            return Color.green.opacity(0.3)
        case .blue:
            return Color.blue.opacity(0.3)
        case .purple:
            return Color.purple.opacity(0.3)
        case .orange:
            return Color.orange.opacity(0.3)
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct Highlight: Identifiable, Codable {
    let id: UUID
    let book: String
    let chapter: Int
    let verse: Int
    let verseText: String
    let color: HighlightColor
    var note: String?
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), book: String, chapter: Int, verse: Int, verseText: String, color: HighlightColor, note: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.verseText = verseText
        self.color = color
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var reference: String {
        "\(book) \(chapter):\(verse)"
    }

    var displayText: String {
        if let note = note, !note.isEmpty {
            return note
        }
        return String(verseText.prefix(100)) + (verseText.count > 100 ? "..." : "")
    }
}
