//
//  EnhancedBibleService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

class EnhancedBibleService: ObservableObject {
    static let shared = EnhancedBibleService()

    @Published var books: [BibleBookInfo] = BibleBookInfo.allBooks
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // Get all books
    func getAllBooks() -> [BibleBookInfo] {
        return BibleBookInfo.allBooks
    }

    // Get books by testament
    func getBooks(testament: Testament) -> [BibleBookInfo] {
        return BibleBookInfo.allBooks.filter { $0.testament == testament}
    }

    // Get a specific chapter
    func getChapter(book: String, chapter: Int) async -> [BibleVerse]? {
        // Using Bible API (https://bible-api.com - free, no key required)
        let bookName = book.replacingOccurrences(of: " ", with: "%20")
        let urlString = "https://bible-api.com/\(bookName)+\(chapter)?translation=kjv"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BibleAPIResponse.self, from: data)

            // Convert to our verse format
            return response.verses.enumerated().map { index, apiVerse in
                BibleVerse(
                    book: apiVerse.book_name,
                    chapter: apiVerse.chapter,
                    verse: apiVerse.verse,
                    text: apiVerse.text,
                    translation: "KJV"
                )
            }
        } catch {
            print("Error fetching chapter: \(error)")
            return nil
        }
    }

    // Get a specific verse
    func getVerse(book: String, chapter: Int, verse: Int) async -> BibleVerse? {
        let bookName = book.replacingOccurrences(of: " ", with: "%20")
        let urlString = "https://bible-api.com/\(bookName)+\(chapter):\(verse)?translation=kjv"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BibleAPIResponse.self, from: data)

            guard let firstVerse = response.verses.first else {
                return nil
            }

            return BibleVerse(
                book: firstVerse.book_name,
                chapter: firstVerse.chapter,
                verse: firstVerse.verse,
                text: firstVerse.text,
                translation: "KJV"
            )
        } catch {
            print("Error fetching verse: \(error)")
            return nil
        }
    }

    // Search verses
    func searchVerses(query: String) async -> [BibleVerse] {
        // For now, return empty since we'd need a search API or local database
        // This would be implemented with a proper Bible API or local SQLite database
        return []
    }

    // Get daily verse
    func getDailyVerse() async -> BibleVerse {
        // Return a popular verse for now
        let popularVerses = [
            ("John", 3, 16),
            ("Psalm", 23, 1),
            ("Proverbs", 3, 5),
            ("Romans", 8, 28),
            ("Philippians", 4, 13),
            ("Jeremiah", 29, 11),
            ("Isaiah", 41, 10),
            ("Matthew", 6, 33)
        ]

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % popularVerses.count
        let (book, chapter, verse) = popularVerses[index]

        if let verseData = await getVerse(book: book, chapter: chapter, verse: verse) {
            return verseData
        }

        // Fallback
        return BibleVerse(
            book: "John",
            chapter: 3,
            verse: 16,
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            translation: "KJV"
        )
    }
}

// API Response structures
struct BibleAPIResponse: Codable {
    let reference: String
    let verses: [BibleAPIVerse]
    let text: String
    let translation_id: String
    let translation_name: String
    let translation_note: String
}

struct BibleAPIVerse: Codable {
    let book_id: String
    let book_name: String
    let chapter: Int
    let verse: Int
    let text: String
}
