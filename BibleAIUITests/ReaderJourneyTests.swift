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
        for _ in 0..<3 { next.tap() }
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
        let saved = app.buttons.containing(.staticText, identifier: "Genesis 1:2").firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        let note = app.textViews["note.text"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.typeText("A quiet moment with Scripture.")
        app.buttons["note.save"].tap()
        XCTAssertTrue(app.staticTexts["A quiet moment with Scripture."].waitForExistence(timeout: 5))
        print("INTERACTION_ASSERTED reader.save")
        print("INTERACTION_ASSERTED note.save")
        capture("saved-note")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["reader.verse.Genesis|1|2"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["A quiet moment with Scripture."].waitForExistence(timeout: 5))
        print("INTERACTION_ASSERTED reader.resume")
        app.buttons.containing(.staticText, identifier: "Genesis 1:2").firstMatch.tap()
        let reopened = app.textViews["note.text"]
        XCTAssertEqual(reopened.value as? String, "A quiet moment with Scripture.")
        reopened.tap()
        reopened.typeText(" Cancelled change")
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.staticTexts["A quiet moment with Scripture. Cancelled change"].exists)
        app.terminate()
        app.launch()
        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["A quiet moment with Scripture."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["A quiet moment with Scripture. Cancelled change"].exists)
        print("INTERACTION_ASSERTED note.cancel")

        app.tabBars.buttons["Read"].tap()
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
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
