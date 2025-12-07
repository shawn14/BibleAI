//
//  Message.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var verseReferences: [VerseReference]?
    var isTyping: Bool

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), verseReferences: [VerseReference]? = nil, isTyping: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.verseReferences = verseReferences
        self.isTyping = isTyping
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

struct VerseReference: Codable, Identifiable {
    let id: UUID
    let book: String
    let chapter: Int
    let verse: Int
    let translation: String
    let text: String

    init(id: UUID = UUID(), book: String, chapter: Int, verse: Int, translation: String = "KJV", text: String) {
        self.id = id
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.translation = translation
        self.text = text
    }

    var reference: String {
        "\(book) \(chapter):\(verse)"
    }
}
