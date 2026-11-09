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
        let catalog = ReadingPlanService.shared.availablePlans
        guard let short = catalog.first(where: { $0.title == "Five Minutes in the Gospels" }) else {
            throw Failure(message: "Five-minute sessions must offer a short passage instead of four full chapters")
        }
        try check(short.dailyReadings.count == 8, "eight five-minute sessions")
        for newReader in [false, true] {
            for peace in [false, true] {
                try check(ReadingPlanService.shared.recommendedPlan(minutes: 5, newReader: newReader, seekingPeace: peace)?.id == short.id,
                          "five minutes honors time before other preferences")
                let ten = ReadingPlanService.shared.recommendedPlan(minutes: 10, newReader: newReader, seekingPeace: peace)
                try check(ten?.dailyReadings.allSatisfy { day in
                    day.readings.count == 1 && day.readings[0].endChapter == nil && day.readings[0].verseRange == nil
                } == true, "ten minutes assigns one full chapter")
            }
        }
        let shortEntries = short.dailyReadings.flatMap(\.readings)
        try check(shortEntries.count == 8 && shortEntries.allSatisfy {
            guard let range = $0.verseRange, let question = $0.reflection else { return false }
            return (1...4).contains(range.count) && !question.isEmpty && $0.endChapter == nil
        }, "each short day assigns one passage and one reflection")
        try check(shortEntries.first?.displayText == "Matthew 1:20–21", "show the passage range, not the full chapter")
        try check(catalog.first { $0.title == "Gospel Tour" }?.dailyReadings.first?.readings.map(\.displayText) == ["Matthew 1-2", "Luke 1-2"],
                  "existing Gospel Tour day one retains four chapters")
        let legacy = Data(#"{"id":"1840EF09-1426-4901-8AFD-3139D908AB1A","book":"John","startChapter":3}"#.utf8)
        let old = try JSONDecoder().decode(ReadingReference.self, from: legacy)
        try check(old.verseRange == nil && old.displayText == "John 3", "old whole-chapter references decode unchanged")
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
        let index = ScriptureIndex(file: URL(fileURLWithPath: "BibleAI/ScriptureIndex/scripture.sqlite3"))
        let kjvHits = try await index.search("ONLY, begotten Son", edition: .kjv)
        try check(kjvHits.verses.contains { $0.place == john && $0.translation == "KJV" },
                  "KJV phrase lookup finds John 3:16 across case and punctuation")
        let webHits = try await index.search("one and only Son", edition: .web)
        try check(webHits.verses.contains { $0.place == john && $0.text == web.text },
                  "WEB result text equals the actual provider's John 3:16")
        let page1 = try await index.search("God", edition: .kjv)
        let page2 = try await index.search("God", edition: .kjv, page: 1)
        try check(page1.hasNext && page1.verses.count == ScriptureIndex.pageSize &&
                  Set(page1.verses.map(\.passageID)).isDisjoint(with: page2.verses.map(\.passageID)),
                  "common words return bounded distinct pages in canonical order")
        let noHits = try await index.search("zzzzzzzzq", edition: .web)
        try check(noHits.verses.isEmpty && !noHits.hasNext, "no matches remain empty")
        let cancelled = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                _ = try await index.search("God", edition: .kjv)
                return false
            } catch {
                return error is CancellationError
            }
        }.value
        try check(cancelled, "a superseded search cannot publish results")
        let offline = ScriptureChapterStore(directory: folder.appendingPathComponent("offline"), index: index)
        let preview = ScriptureFeedModel(defaults: defaults, chapters: offline)
        await preview.start()
        try check(await preview.previewSearchResult(psalm), "word search opens an uncached complete preview chapter")
        await preview.switchEdition(.kjv)
        preview.visibleID = "Psalms|23|2"
        await preview.didScroll()
        let restoredReading = ScriptureFeedModel(defaults: defaults, chapters: offline)
        await restoredReading.start()
        try check(restoredReading.current?.place == john && restoredReading.edition == .web,
                  "quitting a search preview preserves the personal bookmark and edition")
        await preview.returnToReading()
        try check(preview.current?.text == web.text && !preview.isReadingSharedPassage,
                  "returning from a text result restores the exact saved reading")
        let file = folder.appendingPathComponent("library/studies.json")
        let library = StudyLibrary(file: file)
        let study = SavedStudy(verse: web, source: .guide, title: "Persistence check", body: "A saved study body")
        try library.save(study)
        try library.save(SavedStudy(verse: web, source: .guide, title: study.title, body: study.body))
        let restored = StudyLibrary(file: file)
        try check(restored.studies.count == 1 && restored.studies.first?.matches(study) == true, "exact content and edition reopen once from the atomic study file")
        try restored.remove(study.id)
        try check(StudyLibrary(file: file).studies.isEmpty, "removed study stays removed after reopening")
        // Build 12 saved these five fields without a relatedPassage field.
        let oldID = UUID()
        let legacyRecord: [String: Any] = [
            "id": oldID.uuidString, "verse": try JSONSerialization.jsonObject(with: JSONEncoder().encode(web)),
            "source": SavedStudy.Source.guide.rawValue, "title": "Previously saved", "body": "Original commentary"
        ]
        try JSONSerialization.data(withJSONObject: [legacyRecord]).write(to: file)
        let mixedLibrary = StudyLibrary(file: file)
        try check(mixedLibrary.studies.first?.id == oldID && mixedLibrary.studies.first?.relatedPassage == nil &&
                  mixedLibrary.studies.first?.body == "Original commentary", "build 12 saved-study schema reads unchanged")
        let related = StudyPassage(book: "Luke", chapter: 1, first: 26, last: 33)
        let linked = SavedStudy(verse: web, source: .guide, title: "Linked guide", body: "Saved with a cross-reference",
                                relatedPassage: related)
        try mixedLibrary.save(linked)
        let reopenedStudies = StudyLibrary(file: file).studies
        try check(reopenedStudies.count == 2 && reopenedStudies.first?.relatedPassage == related &&
                  reopenedStudies.first?.verse.translation == "WEB" && reopenedStudies.last?.id == oldID,
                  "the linked WEB guide and existing entry survive disk reload together")
        let invalid = Data("invalid".utf8)
        try invalid.write(to: file)
        let corrupt = StudyLibrary(file: file)
        var refused = false
        do { try corrupt.save(study) } catch { refused = true }
        let retained = try Data(contentsOf: file)
        try check(refused && retained == invalid, "a damaged library is reported and cannot be overwritten")
    }
}
