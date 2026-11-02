// Compile through the committed mac-run action with -parse-as-library and actual production models.
// Pure contract/persistence checks. This does not establish iOS share-sheet or link-delivery behavior.
import Foundation

@main
struct GrowthCoreTests {
    @MainActor
    static func main() throws {
        var checks = 0
        var failures = 0
        func check(_ value: Bool, _ label: String) {
            checks += 1
            if !value { failures += 1; print("FAIL \(label)") }
        }
        let invite = UUID()
        func verseLink(book: String = "John", chapter: Int = 3, verse: Int = 16,
                       inviteID: UUID = invite) -> SharedScriptureLink? {
            SharedScriptureLink(verse: BibleVerse(book: book, chapter: chapter, verse: verse,
                                                text: "Not used by link generation"), inviteID: inviteID)
        }
        let link = verseLink()!
        check(link.readingPlace == ReadingPlace(book: "John", chapter: 3, verse: 16), "exact reading place")
        check(SharedScriptureLink(url: link.webURL) == link, "web round trip")
        check(SharedScriptureLink(url: link.appURL) == link, "app round trip")
        check(link.webURL.host == "www.bibleaicompanion.com", "canonical public domain")
        check(link.appURL.scheme == "brightscroll", "custom scheme")
        check(!link.webURL.absoluteString.contains("Not%20used"), "no Scripture text or private data in URL")
        let encoded = try JSONEncoder().encode(link)
        check(try JSONDecoder().decode(SharedScriptureLink.self, from: encoded) == link, "Codable round trip")

        for book in BibleBookInfo.allBooks {
            let first = verseLink(book: book.name, chapter: 1, verse: 1)!
            let last = verseLink(book: book.name, chapter: book.chapterCount, verse: 1)!
            check(SharedScriptureLink(url: first.webURL) == first, "\(book.name) first chapter")
            check(SharedScriptureLink(url: last.appURL) == last, "\(book.name) last chapter")
            check(verseLink(book: book.name, chapter: 0) == nil, "\(book.name) rejects zero chapter")
            check(verseLink(book: book.name, chapter: book.chapterCount + 1) == nil, "\(book.name) rejects chapter past end")
        }
        for planID in SharedScriptureLink.supportedPlanIDs {
            let plan = ReadingPlan(id: planID, title: "Catalog plan", description: "", duration: 1,
                                   category: .devotional, dailyReadings: [])
            let invitation = SharedScriptureLink(plan: plan, inviteID: UUID())!
            check(SharedScriptureLink(url: invitation.webURL) == invitation, "plan web round trip \(planID)")
            check(SharedScriptureLink(url: invitation.appURL) == invitation, "plan app round trip \(planID)")
            check(invitation.readingPlace == nil, "plan has no fake verse")
        }
        let unknownPlan = ReadingPlan(title: "Unknown", description: "", duration: 1,
                                      category: .devotional, dailyReadings: [])
        check(SharedScriptureLink(plan: unknownPlan) == nil, "unknown plan rejected")
        check(verseLink(book: "Invented") == nil, "unknown book rejected")
        check(verseLink(verse: 0) == nil && verseLink(verse: 177) == nil, "verse input bounds")
        check(SharedScriptureLink(verse: BibleVerse(book: "John", chapter: 3, verse: 16, text: "", translation: "NIV")) == nil,
              "unsupported translation rejected")

        let web = link.webURL.absoluteString
        let app = link.appURL.absoluteString
        let badURLs = [
            web.replacingOccurrences(of: "https:", with: "http:"),
            web.replacingOccurrences(of: "www.bibleaicompanion.com", with: "www.bibleaicompanion.com.evil.example"),
            web.replacingOccurrences(of: "www.bibleaicompanion.com", with: "evil@www.bibleaicompanion.com"),
            web.replacingOccurrences(of: "www.bibleaicompanion.com", with: "www.bibleaicompanion.com:443"),
            web.replacingOccurrences(of: "/share?", with: "/share/extra?"),
            web + "#ignored", web + "&kind=verse", web + "&book=Luke", web + "&campaign=unknown",
            web + "&plan=" + SharedScriptureLink.supportedPlanIDs.first!.uuidString,
            web.replacingOccurrences(of: "kind=verse", with: "kind=unknown"),
            web.replacingOccurrences(of: "kind=verse", with: "kind="),
            web.replacingOccurrences(of: "chapter=3", with: "chapter=03"),
            web.replacingOccurrences(of: "chapter=3", with: "chapter=-1"),
            web.replacingOccurrences(of: "verse=16", with: "verse=1e1"),
            web.replacingOccurrences(of: "verse=16", with: "verse=99999999999999999999999999999999"),
            web.replacingOccurrences(of: "book=John", with: "book=john"),
            web.replacingOccurrences(of: invite.uuidString.lowercased(), with: "invalid"),
            web + "&padding=" + String(repeating: "x", count: 2_049),
            app.replacingOccurrences(of: "brightscroll:", with: "otherapp:"),
            app.replacingOccurrences(of: "//share?", with: "//other?"),
            app.replacingOccurrences(of: "//share?", with: "//share/extra?"),
            app.replacingOccurrences(of: "//share?", with: "//share:42?")
        ]
        for bad in badURLs {
            check(URL(string: bad).flatMap(SharedScriptureLink.init(url:)) == nil, "reject malformed/untrusted link")
        }
        let data = String(decoding: encoded, as: UTF8.self).replacingOccurrences(of: "\"John\"", with: "\"Invented\"")
        check((try? JSONDecoder().decode(SharedScriptureLink.self, from: Data(data.utf8))) == nil, "invalid persisted payload rejected")

        let suite = "BibleAI.growth.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var store = GrowthStore(defaults: defaults, now: { now })
        let installationID = store.installationID
        check(store.firstSeenAt == now, "first seen timestamp")
        check(store.readerActivatedAt == nil, "launch is not reader activation")
        check(GrowthStore(defaults: defaults).installationID == installationID, "identity persists before any event")
        check(store.receive(url: link.webURL), "valid receive")
        check(store.pendingInvitation == link && store.acceptedInvitation == nil, "receive requires acceptance")
        check(store.attribution?.isNewReader == true, "first invite classified before onboarding")
        check(!store.recordFirstReading(for: link), "cannot activate before acceptance")
        check(store.receive(url: link.appURL), "same invite may reopen")
        check(store.events.filter { $0.kind == .invitationOpened }.count == 1, "duplicate open deduplicated")
        let changedTarget = verseLink(verse: 17)!
        check(!store.receive(url: changedTarget.webURL), "invite ID cannot change target")
        check(store.pendingInvitation == link, "invalid receive preserves pending state")
        store.dismissInvitation()
        check(store.pendingInvitation == nil && store.attribution?.activatedAt == nil, "dismiss is not acceptance")
        check(store.receive(url: link.appURL), "dismissed invitation may reopen")
        store.completeInvitation()
        check(store.pendingInvitation == nil && store.acceptedInvitation == link, "explicit acceptance")
        check(store.recordReaderActivation(), "first actual reading supplies baseline")
        check(!store.recordReaderActivation(), "baseline counts once")
        check(!store.recordFirstReading(for: changedTarget), "wrong content cannot activate")
        check(store.recordFirstReading(for: link), "exact accepted content activates first new reader")
        check(!store.recordFirstReading(for: link), "repeat activation deduplicated")
        check(store.attribution?.activatedAt == now, "activation timestamp stored")

        store = GrowthStore(defaults: defaults, now: { now })
        check(store.installationID == installationID && store.firstSeenAt == now, "identity/first seen survive reload")
        check(store.readerActivatedAt == now && !store.recordReaderActivation(), "baseline survives reload exactly once")
        check(store.acceptedInvitation == link && store.attribution?.invitation == link, "attribution survives store reload")
        check(!store.recordFirstReading(for: link), "activation dedup survives reload")
        let nextLink = verseLink(verse: 17, inviteID: UUID())!
        check(store.receive(url: nextLink.webURL), "next invitation accepted as content")
        store.completeInvitation()
        check(store.attribution?.invitation == link, "later link cannot overwrite first attribution")
        check(!store.recordFirstReading(for: nextLink), "later invitation cannot claim acquisition")
        check(store.events.filter { $0.kind == .firstReading }.count == 1, "one acquisition activation")
        for _ in 0..<(GrowthStore.eventLimit + 20) { store.record(.sharePresented, for: link) }
        check(store.events.count == GrowthStore.eventLimit, "diagnostic events bounded")
        check(store.receive(url: link.webURL), "first invite reopens after event pruning")
        store.completeInvitation()
        check(!store.events.contains { $0.kind == .invitationOpened || $0.kind == .invitationAccepted },
              "first-touch open/accept remain deduped after event pruning")
        check(!store.recordFirstReading(for: link), "activation stays deduped after pruning")
        let before = store.events.map(\.id)
        store.record(.firstReading, for: link)
        check(store.events.map(\.id) == before, "generic logging cannot manufacture activation")
        store.record(.shareFailed, for: link)
        check(store.events.last?.kind == .shareFailed, "failed activity distinct from cancelled")

        let export = try store.exportSnapshotData()
        check(try store.exportSnapshotData() == export, "unchanged export is byte deterministic")
        let exported = try JSONSerialization.jsonObject(with: export) as! [String: Any]
        check(exported["schemaVersion"] as? Int == 1, "export schema version")
        check(exported["installationID"] as? String == installationID.uuidString, "export actual installation ID")
        let counters = exported["counters"] as! [String: Int]
        check(counters["readerActivated"] == 1, "export includes eligible reader baseline")
        check(counters["firstReading"] == 1, "export exact first attributed activation")
        check(counters["sharePresented"] == GrowthStore.eventLimit + 20, "lifetime totals survive raw event pruning")
        check((exported["events"] as? [Any])?.count == GrowthStore.eventLimit, "export raw history remains bounded")
        check(try GrowthStore(defaults: defaults).exportSnapshotData() == export, "persisted export survives reload")

        defaults.removePersistentDomain(forName: suite)
        defaults.set(true, forKey: "hasCompletedOnboarding")
        let returning = GrowthStore(defaults: defaults, now: { now })
        check(returning.installationID != installationID, "cleared storage is a new installation, not a person claim")
        check(returning.recordReaderActivation(), "existing reader still contributes eligible-installation baseline")
        check(returning.receive(url: link.webURL), "returning reader can receive")
        returning.completeInvitation()
        check(returning.attribution?.isNewReader == false, "existing reader stays returning")
        check(!returning.recordFirstReading(for: link), "returning reader cannot count as new acquisition")
        check(returning.events.filter { $0.kind == .firstReading }.isEmpty, "no inflated returning acquisition")
        defaults.removePersistentDomain(forName: suite)
        let organic = GrowthStore(defaults: defaults, now: { now })
        check(organic.recordReaderActivation(), "organic reader baseline")
        check(organic.receive(url: link.webURL), "active organic reader may open invite")
        organic.completeInvitation()
        check(organic.attribution?.isNewReader == false, "already-active reader is returning even without onboarding flag")
        check(!organic.recordFirstReading(for: link), "existing organic activity cannot become a new acquisition")
        print("Growth core: \(checks) checks; \(failures) failures")
        exit(failures == 0 ? 0 : 1)
    }
}
