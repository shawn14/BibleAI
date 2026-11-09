//
//  BibleVerse.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

enum ReaderEdition: String, CaseIterable, Codable {
    case kjv = "KJV"
    case web = "WEB"

    static let preferenceKey = "reader.preferredEdition"
    static func preferred(in defaults: UserDefaults = .standard) -> Self {
        defaults.string(forKey: preferenceKey).flatMap(Self.init(rawValue:)) ?? .kjv
    }

    var name: String {
        switch self {
        case .kjv: return "King James Version"
        case .web: return "World English Bible"
        }
    }
}

struct BibleVerse: Identifiable, Codable {
    let id: UUID
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
    let translation: String

    init(id: UUID = UUID(), book: String, chapter: Int, verse: Int, text: String, translation: String = "KJV") {
        self.id = id
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.translation = translation
    }

    var reference: String {
        "\(book) \(chapter):\(verse)"
    }

    var fullReference: String {
        "\(reference) (\(translation))"
    }
}

struct BibleBook: Identifiable, Codable {
    let id: UUID
    let name: String
    let testament: Testament
    let numberOfChapters: Int

    init(id: UUID = UUID(), name: String, testament: Testament, numberOfChapters: Int) {
        self.id = id
        self.name = name
        self.testament = testament
        self.numberOfChapters = numberOfChapters
    }
}

enum Testament: String, Codable {
    case old = "Old Testament"
    case new = "New Testament"
}
