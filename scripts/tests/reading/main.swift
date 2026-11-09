import Foundation

@main
struct ReadingProof {
    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func check(_ condition: Bool, _ message: String) throws {
        guard condition else { throw Failure(message: message) }
        print("PASS", message)
    }

    @MainActor static func main() async throws {
        let session = "BibleAI-reading-proof-\(UUID())"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(session)
        let defaults = UserDefaults(suiteName: session)!
        defer {
            defaults.removePersistentDomain(forName: session)
            try? FileManager.default.removeItem(at: folder)
        }
        let store = ScriptureChapterStore(directory: folder.appendingPathComponent("chapters"))
        let reader = ScriptureFeedModel(defaults: defaults, chapters: store)
        let john = ReadingPlace(book: "John", chapter: 3, verse: 16)
        let psalm = ReadingPlace(book: "Psalms", chapter: 23, verse: 1)
        try check(await reader.open(john), "open John 3:16 from the KJV provider")
        try check(reader.current?.text.contains("only begotten Son") == true, "KJV text matches the requested edition")
        await reader.switchEdition(.web)
        guard let web = reader.current else { throw Failure(message: "WEB verse missing") }
        try check(web.place == john && web.translation == "WEB" && web.text.contains("one and only Son"), "WEB switches the wording at the same verse")
        let reopened = ScriptureFeedModel(defaults: defaults, chapters: store)
        await reopened.start()
        try check(reopened.current?.text == web.text && reopened.edition == .web, "saved verse and translation survive model recreation")
        try check(await reopened.open(psalm, asSharedPassage: true, edition: .kjv), "received KJV passage opens")
        reopened.visibleID = "Psalms|23|2"
        await reopened.didScroll()
        let fresh = ScriptureFeedModel(defaults: defaults, chapters: store)
        await fresh.start()
        try check(fresh.current?.place == john && fresh.edition == .web, "closing on a shared verse preserves the personal place and edition")
        await reopened.returnToReading()
        try check(reopened.current?.text == web.text && !reopened.isReadingSharedPassage, "Return restores the original reading")
        let jude = try await store.chapter(book: "Jude", number: 1, edition: .web)
        try check(jude.count == 25 && jude.last?.verse == 25, "all 25 verses of a single-chapter book are readable")
        let file = folder.appendingPathComponent("library/studies.json")
        let library = StudyLibrary(file: file)
        let study = SavedStudy(verse: web, source: .guide, title: "Persistence check", body: "A saved study body")
        try library.save(study)
        try library.save(SavedStudy(verse: web, source: .guide, title: study.title, body: study.body))
        let restored = StudyLibrary(file: file)
        try check(restored.studies.count == 1 && restored.studies.first?.matches(study) == true, "exact content and edition reopen once from the atomic study file")
        try restored.remove(study.id)
        try check(StudyLibrary(file: file).studies.isEmpty, "removed study stays removed after reopening")
        let invalid = Data("invalid".utf8)
        try invalid.write(to: file)
        let corrupt = StudyLibrary(file: file)
        var refused = false
        do { try corrupt.save(study) } catch { refused = true }
        let retained = try Data(contentsOf: file)
        try check(refused && retained == invalid, "a damaged library is reported and cannot be overwritten")
    }
}
