import XCTest

/// Runs on a disposable simulator against the actual Bible provider and app persistence.
/// No provider stubs, test-user purchases, AI requests or production account mutations.
final class ReaderJourneyTests: XCTestCase {
    func testReadSaveNoteResumeAndSearch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let next = app.buttons["onboarding.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        // Intro pages, then the paywall sequence; the plan picker's close keeps free reading.
        var page = 1
        while !app.buttons["paywall.close"].exists {
            XCTAssertLessThanOrEqual(page, 12, "Onboarding never reached the plan picker")
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            capture("onboarding-\(page)")
            next.tap()
            page += 1
            _ = app.buttons["paywall.close"].waitForExistence(timeout: 1)
        }
        capture("onboarding-plans")
        app.buttons["paywall.close"].tap()
        XCTAssertTrue(app.buttons["reader.study"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["reader.verse.Genesis|1|1"].exists)
        capture("reader-initial")
        print("INTERACTION_ASSERTED onboarding.continue")

        app.scrollViews["reader.feed"].swipeUp()
        let verseTwo = app.buttons["reader.verse.Genesis|1|2"]
        XCTAssertTrue(verseTwo.waitForExistence(timeout: 5))
        XCTAssertTrue(verseTwo.isHittable)
        app.buttons["reader.save"].tap()
        XCTAssertEqual(app.buttons["reader.save"].label, "Remove Saved Verse")
        app.tabBars.buttons["Saved"].tap()
        let saved = app.buttons["saved.verse.Genesis|1|2"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        let note = app.textViews["note.text"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.typeText("A quiet moment with Scripture.")
        app.buttons["note.save"].tap()
        assertSavedNote(app, equals: "A quiet moment with Scripture.")
        print("INTERACTION_ASSERTED reader.save")
        print("INTERACTION_ASSERTED note.save")
        capture("saved-note")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["reader.verse.Genesis|1|2"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Saved"].tap()
        assertSavedNote(app, equals: "A quiet moment with Scripture.")
        print("INTERACTION_ASSERTED reader.resume")
        app.buttons["saved.verse.Genesis|1|2"].tap()
        let reopened = app.textViews["note.text"]
        XCTAssertEqual(reopened.value as? String, "A quiet moment with Scripture.")
        reopened.tap()
        reopened.typeText(" Cancelled change")
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.buttons["saved.verse.Genesis|1|2"].label.contains("Cancelled change"))
        app.terminate()
        app.launch()
        app.tabBars.buttons["Saved"].tap()
        assertSavedNote(app, equals: "A quiet moment with Scripture.")
        XCTAssertFalse(app.buttons["saved.verse.Genesis|1|2"].label.contains("Cancelled change"))
        print("INTERACTION_ASSERTED note.cancel")

        app.tabBars.buttons["The Bible"].tap()
        app.buttons["reader.passage"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("John 3:16")
        app.buttons["passage.openReference"].tap()
        let john = app.buttons["reader.verse.John|3|16"]
        XCTAssertTrue(john.waitForExistence(timeout: 30))
        XCTAssertTrue(john.isHittable)
        XCTAssertTrue(john.label.contains("For God so loved the world"))
        print("INTERACTION_ASSERTED passage.reference")
        capture("reader-john-3-16")

        app.buttons["reader.study"].tap()
        XCTAssertTrue(app.buttons["study.Explain This Verse"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["John 3:16 (KJV)"].exists)
        capture("verse-study")
        app.buttons["Done"].tap()
        print("INTERACTION_ASSERTED reader.study")

        app.buttons["reader.options"].tap()
        app.buttons["Reading Settings"].tap()
        XCTAssertTrue(app.sliders["settings.textSize"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Serif Type"].exists)
        capture("reading-settings")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["reader.study"].waitForExistence(timeout: 5))
        print("INTERACTION_ASSERTED settings.openClose")

        try exerciseAllPlanPersistence(app)
    }

    private func assertSavedNote(_ app: XCUIApplication, equals note: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let row = app.buttons["saved.verse.Genesis|1|2"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(row.label.contains(note), "Saved row must expose the persisted note", file: file, line: line)
    }

    private func exerciseAllPlanPersistence(_ app: XCUIApplication) throws {
        let plans = [("Gospel Tour", 8), ("Psalms in a Month", 30),
                     ("New Testament in 30 Days", 30), ("Proverbs Wisdom", 31)]
        app.tabBars.buttons["Plans"].tap()
        capture("reading-plans")
        for (title, duration) in plans {
            openPlan(title, in: app)
            capture("plan-\(title)")
            let start = app.buttons["plan.start"]
            XCTAssertTrue(start.waitForExistence(timeout: 5))
            start.tap()
            let complete = app.buttons["plan.complete.1"]
            reveal(complete, in: app)
            complete.tap()
            XCTAssertTrue(app.staticTexts["Completed"].waitForExistence(timeout: 5))
            app.buttons["Done"].tap()
            let row = app.buttons["plans.open.\(title)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            XCTAssertTrue(row.label.contains("1 of \(duration) readings complete"))
            print("INTERACTION_ASSERTED plan.complete.\(title).1")
        }
        // The same real app store must survive process death for every built-in plan.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Plans"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Plans"].tap()
        for (title, duration) in plans {
            let row = app.buttons["plans.open.\(title)"]
            reveal(row, in: app)
            XCTAssertTrue(row.label.contains("1 of \(duration) readings complete"),
                          "\(title) must retain its day-one completion after relaunch")
            row.tap()
            XCTAssertFalse(app.buttons["plan.start"].exists)
            XCTAssertTrue(app.staticTexts["Completed"].exists)
            XCTAssertFalse(app.buttons["plan.complete.1"].exists)
            capture("plan-restored-\(title)")
            app.buttons["Done"].tap()
            print("INTERACTION_ASSERTED plan.resume.\(title)")
        }
    }

    private func openPlan(_ title: String, in app: XCUIApplication) {
        let row = app.buttons["plans.open.\(title)"]
        reveal(row, in: app)
        row.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Expected control was not reachable: \(element.identifier)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
