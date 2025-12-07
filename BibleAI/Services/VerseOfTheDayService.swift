//
//  VerseOfTheDayService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

struct DailyVerse {
    let reference: String
    let text: String
    let book: String
    let chapter: Int
    let verse: Int
}

class VerseOfTheDayService {
    static let shared = VerseOfTheDayService()

    // Curated collection of meaningful verses
    private let curatedVerses: [(book: String, chapter: Int, verse: Int, reference: String)] = [
        ("John", 3, 16, "John 3:16"),
        ("Psalms", 23, 1, "Psalm 23:1"),
        ("Proverbs", 3, 5, "Proverbs 3:5-6"),
        ("Romans", 8, 28, "Romans 8:28"),
        ("Philippians", 4, 13, "Philippians 4:13"),
        ("Jeremiah", 29, 11, "Jeremiah 29:11"),
        ("Matthew", 6, 33, "Matthew 6:33"),
        ("Isaiah", 40, 31, "Isaiah 40:31"),
        ("Psalms", 46, 1, "Psalm 46:1"),
        ("1 Corinthians", 13, 4, "1 Corinthians 13:4-7"),
        ("Joshua", 1, 9, "Joshua 1:9"),
        ("Proverbs", 16, 3, "Proverbs 16:3"),
        ("Matthew", 11, 28, "Matthew 11:28-30"),
        ("Psalms", 119, 105, "Psalm 119:105"),
        ("Romans", 12, 2, "Romans 12:2"),
        ("Ephesians", 2, 8, "Ephesians 2:8-9"),
        ("James", 1, 2, "James 1:2-4"),
        ("2 Timothy", 1, 7, "2 Timothy 1:7"),
        ("Psalms", 37, 4, "Psalm 37:4"),
        ("Matthew", 5, 14, "Matthew 5:14-16"),
        ("Colossians", 3, 23, "Colossians 3:23"),
        ("Hebrews", 11, 1, "Hebrews 11:1"),
        ("1 Peter", 5, 7, "1 Peter 5:7"),
        ("Galatians", 5, 22, "Galatians 5:22-23"),
        ("Revelation", 21, 4, "Revelation 21:4"),
        ("Psalms", 27, 1, "Psalm 27:1"),
        ("Isaiah", 41, 10, "Isaiah 41:10"),
        ("Matthew", 7, 7, "Matthew 7:7"),
        ("Romans", 5, 8, "Romans 5:8"),
        ("Psalms", 91, 1, "Psalm 91:1-2"),
        ("1 John", 4, 19, "1 John 4:19")
    ]

    private let bibleService = EnhancedBibleService.shared

    // Get verse of the day based on current date
    func getVerseOfTheDay() async -> DailyVerse? {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // Use day of year to select verse (cycles through the collection)
        let index = (dayOfYear - 1) % curatedVerses.count
        let selected = curatedVerses[index]

        // Fetch the actual verse text
        if let verses = await bibleService.getChapter(book: selected.book, chapter: selected.chapter) {
            // Find the specific verse
            if let verseData = verses.first(where: { $0.verse == selected.verse }) {
                return DailyVerse(
                    reference: selected.reference,
                    text: verseData.text,
                    book: selected.book,
                    chapter: selected.chapter,
                    verse: selected.verse
                )
            }
        }

        return nil
    }

    // Get a random verse for inspiration
    func getRandomVerse() async -> DailyVerse? {
        let randomIndex = Int.random(in: 0..<curatedVerses.count)
        let selected = curatedVerses[randomIndex]

        if let verses = await bibleService.getChapter(book: selected.book, chapter: selected.chapter) {
            if let verseData = verses.first(where: { $0.verse == selected.verse }) {
                return DailyVerse(
                    reference: selected.reference,
                    text: verseData.text,
                    book: selected.book,
                    chapter: selected.chapter,
                    verse: selected.verse
                )
            }
        }

        return nil
    }
}
