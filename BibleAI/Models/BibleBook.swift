//
//  BibleBook.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

struct CompleteBibleBook: Identifiable, Codable {
    let id: String
    let name: String
    let abbreviation: String
    let testament: Testament
    let chapters: [[String]] // Array of chapters, each chapter is array of verses

    var numberOfChapters: Int {
        chapters.count
    }

    func getChapter(_ chapterNumber: Int) -> [String]? {
        guard chapterNumber > 0 && chapterNumber <= chapters.count else {
            return nil
        }
        return chapters[chapterNumber - 1]
    }

    func getVerse(chapter: Int, verse: Int) -> String? {
        guard let chapterVerses = getChapter(chapter),
              verse > 0 && verse <= chapterVerses.count else {
            return nil
        }
        return chapterVerses[verse - 1]
    }
}

// Bible Books metadata
struct BibleBookInfo: Hashable {
    let name: String
    let abbreviation: String
    let testament: Testament
    let chapterCount: Int

    static let allBooks: [BibleBookInfo] = [
        // Old Testament
        BibleBookInfo(name: "Genesis", abbreviation: "Gen", testament: .old, chapterCount: 50),
        BibleBookInfo(name: "Exodus", abbreviation: "Exod", testament: .old, chapterCount: 40),
        BibleBookInfo(name: "Leviticus", abbreviation: "Lev", testament: .old, chapterCount: 27),
        BibleBookInfo(name: "Numbers", abbreviation: "Num", testament: .old, chapterCount: 36),
        BibleBookInfo(name: "Deuteronomy", abbreviation: "Deut", testament: .old, chapterCount: 34),
        BibleBookInfo(name: "Joshua", abbreviation: "Josh", testament: .old, chapterCount: 24),
        BibleBookInfo(name: "Judges", abbreviation: "Judg", testament: .old, chapterCount: 21),
        BibleBookInfo(name: "Ruth", abbreviation: "Ruth", testament: .old, chapterCount: 4),
        BibleBookInfo(name: "1 Samuel", abbreviation: "1Sam", testament: .old, chapterCount: 31),
        BibleBookInfo(name: "2 Samuel", abbreviation: "2Sam", testament: .old, chapterCount: 24),
        BibleBookInfo(name: "1 Kings", abbreviation: "1Kgs", testament: .old, chapterCount: 22),
        BibleBookInfo(name: "2 Kings", abbreviation: "2Kgs", testament: .old, chapterCount: 25),
        BibleBookInfo(name: "1 Chronicles", abbreviation: "1Chr", testament: .old, chapterCount: 29),
        BibleBookInfo(name: "2 Chronicles", abbreviation: "2Chr", testament: .old, chapterCount: 36),
        BibleBookInfo(name: "Ezra", abbreviation: "Ezra", testament: .old, chapterCount: 10),
        BibleBookInfo(name: "Nehemiah", abbreviation: "Neh", testament: .old, chapterCount: 13),
        BibleBookInfo(name: "Esther", abbreviation: "Esth", testament: .old, chapterCount: 10),
        BibleBookInfo(name: "Job", abbreviation: "Job", testament: .old, chapterCount: 42),
        BibleBookInfo(name: "Psalms", abbreviation: "Ps", testament: .old, chapterCount: 150),
        BibleBookInfo(name: "Proverbs", abbreviation: "Prov", testament: .old, chapterCount: 31),
        BibleBookInfo(name: "Ecclesiastes", abbreviation: "Eccl", testament: .old, chapterCount: 12),
        BibleBookInfo(name: "Song of Solomon", abbreviation: "Song", testament: .old, chapterCount: 8),
        BibleBookInfo(name: "Isaiah", abbreviation: "Isa", testament: .old, chapterCount: 66),
        BibleBookInfo(name: "Jeremiah", abbreviation: "Jer", testament: .old, chapterCount: 52),
        BibleBookInfo(name: "Lamentations", abbreviation: "Lam", testament: .old, chapterCount: 5),
        BibleBookInfo(name: "Ezekiel", abbreviation: "Ezek", testament: .old, chapterCount: 48),
        BibleBookInfo(name: "Daniel", abbreviation: "Dan", testament: .old, chapterCount: 12),
        BibleBookInfo(name: "Hosea", abbreviation: "Hos", testament: .old, chapterCount: 14),
        BibleBookInfo(name: "Joel", abbreviation: "Joel", testament: .old, chapterCount: 3),
        BibleBookInfo(name: "Amos", abbreviation: "Amos", testament: .old, chapterCount: 9),
        BibleBookInfo(name: "Obadiah", abbreviation: "Obad", testament: .old, chapterCount: 1),
        BibleBookInfo(name: "Jonah", abbreviation: "Jonah", testament: .old, chapterCount: 4),
        BibleBookInfo(name: "Micah", abbreviation: "Mic", testament: .old, chapterCount: 7),
        BibleBookInfo(name: "Nahum", abbreviation: "Nah", testament: .old, chapterCount: 3),
        BibleBookInfo(name: "Habakkuk", abbreviation: "Hab", testament: .old, chapterCount: 3),
        BibleBookInfo(name: "Zephaniah", abbreviation: "Zeph", testament: .old, chapterCount: 3),
        BibleBookInfo(name: "Haggai", abbreviation: "Hag", testament: .old, chapterCount: 2),
        BibleBookInfo(name: "Zechariah", abbreviation: "Zech", testament: .old, chapterCount: 14),
        BibleBookInfo(name: "Malachi", abbreviation: "Mal", testament: .old, chapterCount: 4),

        // New Testament
        BibleBookInfo(name: "Matthew", abbreviation: "Matt", testament: .new, chapterCount: 28),
        BibleBookInfo(name: "Mark", abbreviation: "Mark", testament: .new, chapterCount: 16),
        BibleBookInfo(name: "Luke", abbreviation: "Luke", testament: .new, chapterCount: 24),
        BibleBookInfo(name: "John", abbreviation: "John", testament: .new, chapterCount: 21),
        BibleBookInfo(name: "Acts", abbreviation: "Acts", testament: .new, chapterCount: 28),
        BibleBookInfo(name: "Romans", abbreviation: "Rom", testament: .new, chapterCount: 16),
        BibleBookInfo(name: "1 Corinthians", abbreviation: "1Cor", testament: .new, chapterCount: 16),
        BibleBookInfo(name: "2 Corinthians", abbreviation: "2Cor", testament: .new, chapterCount: 13),
        BibleBookInfo(name: "Galatians", abbreviation: "Gal", testament: .new, chapterCount: 6),
        BibleBookInfo(name: "Ephesians", abbreviation: "Eph", testament: .new, chapterCount: 6),
        BibleBookInfo(name: "Philippians", abbreviation: "Phil", testament: .new, chapterCount: 4),
        BibleBookInfo(name: "Colossians", abbreviation: "Col", testament: .new, chapterCount: 4),
        BibleBookInfo(name: "1 Thessalonians", abbreviation: "1Thess", testament: .new, chapterCount: 5),
        BibleBookInfo(name: "2 Thessalonians", abbreviation: "2Thess", testament: .new, chapterCount: 3),
        BibleBookInfo(name: "1 Timothy", abbreviation: "1Tim", testament: .new, chapterCount: 6),
        BibleBookInfo(name: "2 Timothy", abbreviation: "2Tim", testament: .new, chapterCount: 4),
        BibleBookInfo(name: "Titus", abbreviation: "Titus", testament: .new, chapterCount: 3),
        BibleBookInfo(name: "Philemon", abbreviation: "Phlm", testament: .new, chapterCount: 1),
        BibleBookInfo(name: "Hebrews", abbreviation: "Heb", testament: .new, chapterCount: 13),
        BibleBookInfo(name: "James", abbreviation: "Jas", testament: .new, chapterCount: 5),
        BibleBookInfo(name: "1 Peter", abbreviation: "1Pet", testament: .new, chapterCount: 5),
        BibleBookInfo(name: "2 Peter", abbreviation: "2Pet", testament: .new, chapterCount: 3),
        BibleBookInfo(name: "1 John", abbreviation: "1John", testament: .new, chapterCount: 5),
        BibleBookInfo(name: "2 John", abbreviation: "2John", testament: .new, chapterCount: 1),
        BibleBookInfo(name: "3 John", abbreviation: "3John", testament: .new, chapterCount: 1),
        BibleBookInfo(name: "Jude", abbreviation: "Jude", testament: .new, chapterCount: 1),
        BibleBookInfo(name: "Revelation", abbreviation: "Rev", testament: .new, chapterCount: 22)
    ]
}
