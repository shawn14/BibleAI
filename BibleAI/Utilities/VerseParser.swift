//
//  VerseParser.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

struct ParsedVerseReference: Equatable {
    let book: String
    let chapter: Int
    let verse: Int?
    let endVerse: Int?

    var displayString: String {
        var result = "\(book) \(chapter)"
        if let verse = verse {
            result += ":\(verse)"
            if let endVerse = endVerse, endVerse != verse {
                result += "-\(endVerse)"
            }
        }
        return result
    }
}

class VerseParser {
    static let shared = VerseParser()

    // Common Bible book names and abbreviations
    private let bookMappings: [String: String] = [
        // Old Testament
        "genesis": "Genesis", "gen": "Genesis", "ge": "Genesis", "gn": "Genesis",
        "exodus": "Exodus", "exod": "Exodus", "exo": "Exodus", "ex": "Exodus",
        "leviticus": "Leviticus", "lev": "Leviticus", "le": "Leviticus", "lv": "Leviticus",
        "numbers": "Numbers", "num": "Numbers", "nu": "Numbers", "nm": "Numbers", "nb": "Numbers",
        "deuteronomy": "Deuteronomy", "deut": "Deuteronomy", "deu": "Deuteronomy", "de": "Deuteronomy", "dt": "Deuteronomy",
        "joshua": "Joshua", "josh": "Joshua", "jos": "Joshua", "jsh": "Joshua",
        "judges": "Judges", "judg": "Judges", "jdg": "Judges", "jg": "Judges", "jdgs": "Judges",
        "ruth": "Ruth", "rth": "Ruth", "ru": "Ruth",
        "1 samuel": "1 Samuel", "1samuel": "1 Samuel", "1sam": "1 Samuel", "1sa": "1 Samuel", "1s": "1 Samuel",
        "2 samuel": "2 Samuel", "2samuel": "2 Samuel", "2sam": "2 Samuel", "2sa": "2 Samuel", "2s": "2 Samuel",
        "1 kings": "1 Kings", "1kings": "1 Kings", "1kgs": "1 Kings", "1ki": "1 Kings", "1k": "1 Kings",
        "2 kings": "2 Kings", "2kings": "2 Kings", "2kgs": "2 Kings", "2ki": "2 Kings", "2k": "2 Kings",
        "1 chronicles": "1 Chronicles", "1chronicles": "1 Chronicles", "1chr": "1 Chronicles", "1ch": "1 Chronicles",
        "2 chronicles": "2 Chronicles", "2chronicles": "2 Chronicles", "2chr": "2 Chronicles", "2ch": "2 Chronicles",
        "ezra": "Ezra", "ezr": "Ezra", "ez": "Ezra",
        "nehemiah": "Nehemiah", "neh": "Nehemiah", "ne": "Nehemiah",
        "esther": "Esther", "esth": "Esther", "est": "Esther", "es": "Esther",
        "job": "Job", "jb": "Job",
        "psalm": "Psalms", "psalms": "Psalms", "ps": "Psalms", "psa": "Psalms", "psm": "Psalms", "pss": "Psalms",
        "proverbs": "Proverbs", "prov": "Proverbs", "pro": "Proverbs", "prv": "Proverbs", "pr": "Proverbs",
        "ecclesiastes": "Ecclesiastes", "eccles": "Ecclesiastes", "eccle": "Ecclesiastes", "ecc": "Ecclesiastes", "ec": "Ecclesiastes",
        "song of solomon": "Song of Solomon", "song": "Song of Solomon", "sos": "Song of Solomon", "so": "Song of Solomon",
        "isaiah": "Isaiah", "isa": "Isaiah", "is": "Isaiah",
        "jeremiah": "Jeremiah", "jer": "Jeremiah", "je": "Jeremiah", "jr": "Jeremiah",
        "lamentations": "Lamentations", "lam": "Lamentations", "la": "Lamentations",
        "ezekiel": "Ezekiel", "ezek": "Ezekiel", "eze": "Ezekiel", "ezk": "Ezekiel",
        "daniel": "Daniel", "dan": "Daniel", "da": "Daniel", "dn": "Daniel",
        "hosea": "Hosea", "hos": "Hosea", "ho": "Hosea",
        "joel": "Joel", "joe": "Joel", "jl": "Joel",
        "amos": "Amos", "amo": "Amos", "am": "Amos",
        "obadiah": "Obadiah", "obad": "Obadiah", "oba": "Obadiah", "ob": "Obadiah",
        "jonah": "Jonah", "jnh": "Jonah", "jon": "Jonah",
        "micah": "Micah", "mic": "Micah", "mi": "Micah",
        "nahum": "Nahum", "nah": "Nahum", "na": "Nahum",
        "habakkuk": "Habakkuk", "hab": "Habakkuk", "hb": "Habakkuk",
        "zephaniah": "Zephaniah", "zeph": "Zephaniah", "zep": "Zephaniah", "zp": "Zephaniah",
        "haggai": "Haggai", "hag": "Haggai", "hg": "Haggai",
        "zechariah": "Zechariah", "zech": "Zechariah", "zec": "Zechariah", "zc": "Zechariah",
        "malachi": "Malachi", "mal": "Malachi", "ml": "Malachi",

        // New Testament
        "matthew": "Matthew", "matt": "Matthew", "mat": "Matthew", "mt": "Matthew",
        "mark": "Mark", "mar": "Mark", "mrk": "Mark", "mk": "Mark", "mr": "Mark",
        "luke": "Luke", "luk": "Luke", "lk": "Luke",
        "john": "John", "joh": "John", "jhn": "John", "jn": "John",
        "acts": "Acts", "act": "Acts", "ac": "Acts",
        "romans": "Romans", "rom": "Romans", "ro": "Romans", "rm": "Romans",
        "1 corinthians": "1 Corinthians", "1corinthians": "1 Corinthians", "1cor": "1 Corinthians", "1co": "1 Corinthians",
        "2 corinthians": "2 Corinthians", "2corinthians": "2 Corinthians", "2cor": "2 Corinthians", "2co": "2 Corinthians",
        "galatians": "Galatians", "gal": "Galatians", "ga": "Galatians",
        "ephesians": "Ephesians", "eph": "Ephesians", "ephes": "Ephesians",
        "philippians": "Philippians", "phil": "Philippians", "php": "Philippians", "pp": "Philippians",
        "colossians": "Colossians", "col": "Colossians", "co": "Colossians",
        "1 thessalonians": "1 Thessalonians", "1thessalonians": "1 Thessalonians", "1thess": "1 Thessalonians", "1th": "1 Thessalonians",
        "2 thessalonians": "2 Thessalonians", "2thessalonians": "2 Thessalonians", "2thess": "2 Thessalonians", "2th": "2 Thessalonians",
        "1 timothy": "1 Timothy", "1timothy": "1 Timothy", "1tim": "1 Timothy", "1ti": "1 Timothy",
        "2 timothy": "2 Timothy", "2timothy": "2 Timothy", "2tim": "2 Timothy", "2ti": "2 Timothy",
        "titus": "Titus", "tit": "Titus", "ti": "Titus",
        "philemon": "Philemon", "philem": "Philemon", "phm": "Philemon", "pm": "Philemon",
        "hebrews": "Hebrews", "heb": "Hebrews", "he": "Hebrews",
        "james": "James", "jas": "James", "jm": "James",
        "1 peter": "1 Peter", "1peter": "1 Peter", "1pet": "1 Peter", "1pe": "1 Peter", "1pt": "1 Peter", "1p": "1 Peter",
        "2 peter": "2 Peter", "2peter": "2 Peter", "2pet": "2 Peter", "2pe": "2 Peter", "2pt": "2 Peter", "2p": "2 Peter",
        "1 john": "1 John", "1john": "1 John", "1jn": "1 John", "1j": "1 John",
        "2 john": "2 John", "2john": "2 John", "2jn": "2 John", "2j": "2 John",
        "3 john": "3 John", "3john": "3 John", "3jn": "3 John", "3j": "3 John",
        "jude": "Jude", "jud": "Jude", "jd": "Jude",
        "revelation": "Revelation", "rev": "Revelation", "re": "Revelation", "rv": "Revelation"
    ]

    // Parse a verse reference string like "John 3:16" or "Genesis 1:1-3"
    func parseReference(_ text: String) -> ParsedVerseReference? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Pattern: BookName Chapter:Verse or BookName Chapter:Verse-EndVerse
        let pattern = #"([1-3]?\s?[A-Za-z]+)\s+(\d+)(?::(\d+)(?:-(\d+))?)?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(cleaned.startIndex..., in: cleaned)) else {
            return nil
        }

        guard let bookRange = Range(match.range(at: 1), in: cleaned),
              let chapterRange = Range(match.range(at: 2), in: cleaned) else {
            return nil
        }

        let bookInput = String(cleaned[bookRange]).lowercased().trimmingCharacters(in: .whitespaces)
        guard let book = bookMappings[bookInput] else {
            return nil
        }

        guard let chapter = Int(cleaned[chapterRange]) else {
            return nil
        }

        var verse: Int? = nil
        var endVerse: Int? = nil

        if match.range(at: 3).location != NSNotFound,
           let verseRange = Range(match.range(at: 3), in: cleaned) {
            verse = Int(cleaned[verseRange])
        }

        if match.range(at: 4).location != NSNotFound,
           let endVerseRange = Range(match.range(at: 4), in: cleaned) {
            endVerse = Int(cleaned[endVerseRange])
        }

        return ParsedVerseReference(book: book, chapter: chapter, verse: verse, endVerse: endVerse)
    }

    // Find all verse references in a text
    func findReferences(in text: String) -> [(range: NSRange, reference: ParsedVerseReference)] {
        let pattern = #"([1-3]?\s?[A-Za-z]+)\s+(\d+)(?::(\d+)(?:-(\d+))?)?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        var results: [(range: NSRange, reference: ParsedVerseReference)] = []

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let matchText = String(text[matchRange])

            if let reference = parseReference(matchText) {
                results.append((range: match.range, reference: reference))
            }
        }

        return results
    }
}
