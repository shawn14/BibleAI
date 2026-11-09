import Foundation
import SQLite3

/// Each operation reads one page of matches or one chapter from the bundled, read-only index.
actor ScriptureIndex {
    static let shared = ScriptureIndex()
    static let pageSize = 30

    struct Page {
        let verses: [BibleVerse]
        let hasNext: Bool
    }

    enum LookupError: LocalizedError {
        case unavailable, longQuery

        var errorDescription: String? {
            switch self {
            case .unavailable: return "The Scripture search index could not be opened."
            case .longQuery: return "Try a shorter phrase of up to 512 characters."
            }
        }
    }

    private let file: URL?

    init(file: URL? = Bundle.main.url(forResource: "scripture", withExtension: "sqlite3",
                                      subdirectory: "ScriptureIndex")) {
        self.file = file
    }

    func search(_ query: String, edition: ReaderEdition, page: Int = 0) throws -> Page {
        try Task.checkCancellation()
        guard query.count <= 512 else { throw LookupError.longQuery }
        guard query.rangeOfCharacter(from: .alphanumerics) != nil else { return Page(verses: [], hasNext: false) }
        guard page >= 0, page <= Int(Int32.max) / Self.pageSize else { return Page(verses: [], hasNext: false) }
        let table = edition.rawValue.lowercased()
        // A quoted FTS phrase treats AND/OR/* and apostrophes as input, never search operators.
        let phrase = "\"" + query.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        let sql = "SELECT rowid, text FROM \(table) WHERE \(table) MATCH ? ORDER BY rowid LIMIT ? OFFSET ?"
        let matches = try rows(sql, edition: edition) { statement in
            guard sqlite3_bind_text(statement, 1, phrase, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) == SQLITE_OK,
                  sqlite3_bind_int(statement, 2, Int32(Self.pageSize + 1)) == SQLITE_OK else { return false }
            return sqlite3_bind_int(statement, 3, Int32(page * Self.pageSize)) == SQLITE_OK
        }
        return Page(verses: Array(matches.prefix(Self.pageSize)), hasNext: matches.count > Self.pageSize)
    }

    func chapter(book: String, number: Int, edition: ReaderEdition) throws -> [BibleVerse] {
        guard let index = BibleBookInfo.allBooks.firstIndex(where: { $0.name == book }),
              (1...BibleBookInfo.allBooks[index].chapterCount).contains(number) else { return [] }
        let start = Int64((index + 1) * 1_000_000 + number * 1_000)
        return try rows("SELECT rowid, text FROM \(edition.rawValue.lowercased()) WHERE rowid BETWEEN ? AND ? ORDER BY rowid",
                        edition: edition) { statement in
            sqlite3_bind_int64(statement, 1, start + 1) == SQLITE_OK &&
                sqlite3_bind_int64(statement, 2, start + 999) == SQLITE_OK
        }
    }

    private func rows(_ sql: String, edition: ReaderEdition,
                      bind: (OpaquePointer) -> Bool) throws -> [BibleVerse] {
        try Task.checkCancellation()
        guard let file else { throw LookupError.unavailable }
        var handle: OpaquePointer?
        let status = sqlite3_open_v2(file.path, &handle, SQLITE_OPEN_READONLY, nil)
        defer { sqlite3_close(handle) }
        guard status == SQLITE_OK, let db = handle else { throw LookupError.unavailable }
        sqlite3_progress_handler(db, 250, { _ in Task.isCancelled ? 1 : 0 }, nil)

        var prepared: OpaquePointer?
        defer { sqlite3_finalize(prepared) }
        guard sqlite3_prepare_v2(db, sql, -1, &prepared, nil) == SQLITE_OK,
              let statement = prepared, bind(statement) else { throw LookupError.unavailable }

        var result: [BibleVerse] = []
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            try Task.checkCancellation()
            let row = Int(sqlite3_column_int64(statement, 0))
            let bookIndex = row / 1_000_000 - 1
            guard BibleBookInfo.allBooks.indices.contains(bookIndex),
                  let text = sqlite3_column_text(statement, 1) else { throw LookupError.unavailable }
            result.append(BibleVerse(book: BibleBookInfo.allBooks[bookIndex].name,
                                     chapter: row / 1_000 % 1_000, verse: row % 1_000,
                                     text: String(cString: text), translation: edition.rawValue))
            step = sqlite3_step(statement)
        }
        try Task.checkCancellation()
        guard step == SQLITE_DONE else { throw LookupError.unavailable }
        return result
    }
}
