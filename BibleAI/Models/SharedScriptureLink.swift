import Foundation

/// A public Scripture/plan invitation. Never carries private notes or a recipient's identity.
struct SharedScriptureLink: Codable, Equatable, Identifiable {
    enum Kind: String, Codable { case verse, plan }

    let kind: Kind
    let book: String?
    let chapter: Int?
    let verse: Int?
    let planID: UUID?
    let inviteID: UUID
    var id: UUID { inviteID }

    // These are the stable catalog IDs in ReadingPlanService, not newly generated plan IDs.
    static let supportedPlanIDs: Set<UUID> = Set([
        "6F1C2A10-0001-4B1A-9E1E-0000000000A1",
        "6F1C2A10-0002-4B1A-9E1E-0000000000A2",
        "6F1C2A10-0003-4B1A-9E1E-0000000000A3",
        "6F1C2A10-0004-4B1A-9E1E-0000000000A4"
    ].compactMap(UUID.init(uuidString:)))

    init?(verse: BibleVerse, inviteID: UUID = UUID()) {
        guard ReaderEdition(rawValue: verse.translation) != nil,
              Self.validPassage(book: verse.book, chapter: verse.chapter, verse: verse.verse) else { return nil }
        self.kind = .verse
        self.book = verse.book
        self.chapter = verse.chapter
        self.verse = verse.verse
        self.planID = nil
        self.inviteID = inviteID
    }

    init?(plan: ReadingPlan, inviteID: UUID = UUID()) {
        guard Self.supportedPlanIDs.contains(plan.id) else { return nil }
        self.kind = .plan
        self.book = nil
        self.chapter = nil
        self.verse = nil
        self.planID = plan.id
        self.inviteID = inviteID
    }

    init?(url: URL) {
        guard url.absoluteString.utf8.count <= 2_048,
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.user == nil, parts.password == nil, parts.port == nil, parts.fragment == nil else { return nil }
        let isWeb = parts.scheme == "https"
            && ["www.bibleaicompanion.com", "bibleaicompanion.com"].contains(parts.host ?? "")
            && parts.path == "/share"
        let isApp = parts.scheme == "brightscroll" && parts.host == "share" && parts.path.isEmpty
        guard isWeb || isApp, let query = parts.queryItems else { return nil }
        var values: [String: String] = [:]
        for item in query {
            guard values[item.name] == nil, let value = item.value, !value.isEmpty else { return nil }
            values[item.name] = value
        }
        guard let kindValue = values["kind"], let kind = Kind(rawValue: kindValue),
              let token = values["invite"], let invite = Self.canonicalUUID(token) else { return nil }
        switch kind {
        case .verse:
            guard Set(values.keys) == Set(["kind", "book", "chapter", "verse", "invite"]),
                  let book = values["book"], let chapterValue = values["chapter"], let verseValue = values["verse"],
                  let chapter = Int(chapterValue), String(chapter) == chapterValue,
                  let verse = Int(verseValue), String(verse) == verseValue,
                  Self.validPassage(book: book, chapter: chapter, verse: verse) else { return nil }
            self.book = book
            self.chapter = chapter
            self.verse = verse
            self.planID = nil
        case .plan:
            guard Set(values.keys) == Set(["kind", "plan", "invite"]),
                  let planValue = values["plan"], let planID = Self.canonicalUUID(planValue),
                  Self.supportedPlanIDs.contains(planID) else { return nil }
            self.book = nil
            self.chapter = nil
            self.verse = nil
            self.planID = planID
        }
        self.kind = kind
        self.inviteID = invite
    }

    var webURL: URL { makeURL(scheme: "https", host: "www.bibleaicompanion.com", path: "/share") }
    var appURL: URL { makeURL(scheme: "brightscroll", host: "share", path: "") }
    var readingPlace: ReadingPlace? {
        guard kind == .verse, let book, let chapter, let verse else { return nil }
        return ReadingPlace(book: book, chapter: chapter, verse: verse)
    }

    private func makeURL(scheme: String, host: String, path: String) -> URL {
        var parts = URLComponents()
        parts.scheme = scheme
        parts.host = host
        parts.path = path
        var query = [URLQueryItem(name: "kind", value: kind.rawValue)]
        switch kind {
        case .verse:
            query += [URLQueryItem(name: "book", value: book),
                      URLQueryItem(name: "chapter", value: chapter.map(String.init)),
                      URLQueryItem(name: "verse", value: verse.map(String.init))]
        case .plan:
            query.append(URLQueryItem(name: "plan", value: planID?.uuidString.lowercased()))
        }
        query.append(URLQueryItem(name: "invite", value: inviteID.uuidString.lowercased()))
        parts.queryItems = query
        // All fields have passed the bounded constructors/decoder; URLComponents handles escaping.
        return parts.url!
    }

    private static func canonicalUUID(_ text: String) -> UUID? {
        guard text.count == 36, let value = UUID(uuidString: text),
              value.uuidString.lowercased() == text.lowercased() else { return nil }
        return value
    }

    private static func validPassage(book: String, chapter: Int, verse: Int) -> Bool {
        guard let info = BibleBookInfo.allBooks.first(where: { $0.name == book }),
              (1...info.chapterCount).contains(chapter), (1...176).contains(verse) else { return false }
        // 176 is only an input ceiling. ScriptureFeedModel verifies this verse exists in the actual chapter.
        return true
    }

    private enum CodingKeys: String, CodingKey { case kind, book, chapter, verse, planID, inviteID }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        kind = try values.decode(Kind.self, forKey: .kind)
        book = try values.decodeIfPresent(String.self, forKey: .book)
        chapter = try values.decodeIfPresent(Int.self, forKey: .chapter)
        verse = try values.decodeIfPresent(Int.self, forKey: .verse)
        planID = try values.decodeIfPresent(UUID.self, forKey: .planID)
        inviteID = try values.decode(UUID.self, forKey: .inviteID)
        let valid: Bool
        switch kind {
        case .verse:
            valid = planID == nil && book != nil && chapter != nil && verse != nil
                && Self.validPassage(book: book ?? "", chapter: chapter ?? 0, verse: verse ?? 0)
        case .plan:
            valid = book == nil && chapter == nil && verse == nil
                && planID.map(Self.supportedPlanIDs.contains) == true
        }
        guard valid else {
            throw DecodingError.dataCorruptedError(forKey: .kind, in: values, debugDescription: "Invalid shared content")
        }
    }
}
