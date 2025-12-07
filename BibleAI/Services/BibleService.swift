//
//  BibleService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

class BibleService {
    static let shared = BibleService()

    private init() {}

    // Sample Bible data - In production, this would come from a proper Bible API or local database
    private let sampleVerses: [String: BibleVerse] = [
        "John 3:16": BibleVerse(
            book: "John",
            chapter: 3,
            verse: 16,
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            translation: "KJV"
        ),
        "Psalm 23:1": BibleVerse(
            book: "Psalm",
            chapter: 23,
            verse: 1,
            text: "The LORD is my shepherd; I shall not want.",
            translation: "KJV"
        ),
        "Proverbs 3:5": BibleVerse(
            book: "Proverbs",
            chapter: 3,
            verse: 5,
            text: "Trust in the LORD with all thine heart; and lean not unto thine own understanding.",
            translation: "KJV"
        ),
        "Romans 8:28": BibleVerse(
            book: "Romans",
            chapter: 8,
            verse: 28,
            text: "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
            translation: "KJV"
        ),
        "Philippians 4:13": BibleVerse(
            book: "Philippians",
            chapter: 4,
            verse: 13,
            text: "I can do all things through Christ which strengtheneth me.",
            translation: "KJV"
        )
    ]

    func getVerse(book: String, chapter: Int, verse: Int, translation: String = "KJV") async -> BibleVerse? {
        let key = "\(book) \(chapter):\(verse)"

        // Simulate API delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        return sampleVerses[key]
    }

    func searchVerses(query: String) async -> [BibleVerse] {
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Simple search in sample data
        let searchTerm = query.lowercased()
        return sampleVerses.values.filter { verse in
            verse.text.lowercased().contains(searchTerm) ||
            verse.book.lowercased().contains(searchTerm)
        }
    }

    func getDailyVerse() async -> BibleVerse {
        // In production, this would return a different verse each day
        let verses = Array(sampleVerses.values)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % verses.count
        return verses[index]
    }

    func parseVerseReference(_ text: String) -> (book: String, chapter: Int, verse: Int)? {
        // Simple regex to parse verse references like "John 3:16"
        let pattern = #"([1-3]?\s?[A-Za-z]+)\s+(\d+):(\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        guard let bookRange = Range(match.range(at: 1), in: text),
              let chapterRange = Range(match.range(at: 2), in: text),
              let verseRange = Range(match.range(at: 3), in: text) else {
            return nil
        }

        let book = String(text[bookRange]).trimmingCharacters(in: .whitespaces)
        guard let chapter = Int(text[chapterRange]),
              let verse = Int(text[verseRange]) else {
            return nil
        }

        return (book, chapter, verse)
    }

    // Bible books for reference
    let bibleBooks: [BibleBook] = [
        // Old Testament
        BibleBook(name: "Genesis", testament: .old, numberOfChapters: 50),
        BibleBook(name: "Exodus", testament: .old, numberOfChapters: 40),
        BibleBook(name: "Leviticus", testament: .old, numberOfChapters: 27),
        BibleBook(name: "Numbers", testament: .old, numberOfChapters: 36),
        BibleBook(name: "Deuteronomy", testament: .old, numberOfChapters: 34),
        BibleBook(name: "Psalms", testament: .old, numberOfChapters: 150),
        BibleBook(name: "Proverbs", testament: .old, numberOfChapters: 31),
        // New Testament
        BibleBook(name: "Matthew", testament: .new, numberOfChapters: 28),
        BibleBook(name: "Mark", testament: .new, numberOfChapters: 16),
        BibleBook(name: "Luke", testament: .new, numberOfChapters: 24),
        BibleBook(name: "John", testament: .new, numberOfChapters: 21),
        BibleBook(name: "Acts", testament: .new, numberOfChapters: 28),
        BibleBook(name: "Romans", testament: .new, numberOfChapters: 16),
        BibleBook(name: "Philippians", testament: .new, numberOfChapters: 4),
        BibleBook(name: "Revelation", testament: .new, numberOfChapters: 22)
    ]
}
