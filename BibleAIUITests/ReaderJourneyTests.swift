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
            XCTAssertLessThanOrEqual(page, 18, "Onboarding never reached the plan picker")
            let allPlans = app.buttons["onboarding.allPlans"]
            XCTAssertTrue(next.waitForExistence(timeout: 5) || allPlans.exists
                      || app.descendants(matching: .any)["onboarding.commit"].exists)
            capture("onboarding-\(page)")
            // Personal questions: pick the first answer before continuing.
            let option = app.buttons["onboarding.option.0"]
            if option.exists { option.tap() }
            let commit = app.descendants(matching: .any)["onboarding.commit"]
            if commit.exists {
                commit.press(forDuration: 1.8)
                _ = next.waitForExistence(timeout: 3)
            } else if allPlans.exists {
                // The trial timeline's main button starts a purchase; take "View all plans" instead.
                allPlans.tap()
            } else {
                next.tap()
            }
            allowSystemAlert()
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
        sleep(1) // iPad scroll momentum settles more slowly; save acts on the verse that settles on screen
        app.buttons["reader.save"].tap()
        let removeLabel = NSPredicate(format: "label == %@", "Remove Saved Verse")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: removeLabel, evaluatedWith: app.buttons["reader.save"])], timeout: 3), .completed)
        tab("Saved", in: app).tap()
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
        tab("Saved", in: app).tap()
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
        tab("Saved", in: app).tap()
        assertSavedNote(app, equals: "A quiet moment with Scripture.")
        XCTAssertFalse(app.buttons["saved.verse.Genesis|1|2"].label.contains("Cancelled change"))
        print("INTERACTION_ASSERTED note.cancel")

        tab("The Bible", in: app).tap()
        app.buttons["reader.passage"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("John 3:16")
        // The list drops its "Start Here" rows as the query arrives; tapping mid-animation can land on
        // "The Beginning" (Genesis 1) instead of the parsed reference.
        let openReference = app.buttons["passage.openReference"]
        XCTAssertTrue(openReference.waitForExistence(timeout: 5))
        let settled = NSPredicate(format: "exists == false")
        _ = XCTWaiter.wait(for: [expectation(for: settled, evaluatedWith: app.staticTexts["The Beginning"])], timeout: 5)
        openReference.tap()
        let john = app.buttons["reader.verse.John|3|16"]
        XCTAssertTrue(john.waitForExistence(timeout: 30))
        // The passage sheet is still animating closed when the verse first appears.
        let hittable = NSPredicate(format: "isHittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: hittable, evaluatedWith: john)], timeout: 5), .completed)
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
        tab("Plans", in: app).tap()
        capture("reading-plans")
        for (title, duration) in plans {
            openPlan(title, in: app)
            capture("plan-\(title)")
            // Onboarding's "Your plan is ready" step may already have started the recommended plan.
            let start = app.buttons["plan.start"]
            if start.waitForExistence(timeout: 3) { start.tap() }
            let complete = app.buttons["plan.complete.1"]
            reveal(complete, in: app)
            complete.tap()
            // Day-complete screen with the reading streak.
            XCTAssertTrue(app.staticTexts["streak.title"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["streak.count"].label, "1")
            capture("day-complete-\(title)")
            app.buttons["streak.continue"].tap()
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
        XCTAssertTrue(tab("Plans", in: app).waitForExistence(timeout: 10))
        tab("Plans", in: app).tap()
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

    /// Drives the app slowly while scripts/preview-video.sh records the simulator screen.
    /// Not part of the reader proof; run it alone with -only-testing.
    func testPreviewRecording() throws {
        // Recording only: it completes onboarding, which would break the reader journey that follows.
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RECORD_PREVIEW"] == "1", "Run by scripts/preview-video.sh")
        let app = XCUIApplication()
        app.launch()
        let next = app.buttons["onboarding.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        sleep(2)
        for _ in 0..<5 { next.tap(); sleep(2) }
        for _ in 0..<16 where !app.buttons["paywall.close"].exists {
            let option = app.buttons["onboarding.option.0"]
            if option.exists { option.tap(); sleep(1) }
            let commit = app.descendants(matching: .any)["onboarding.commit"]
            if commit.exists { commit.press(forDuration: 1.8); sleep(1) }
            else if app.buttons["onboarding.allPlans"].exists { app.buttons["onboarding.allPlans"].tap() }
            else if next.exists { next.tap() }
            allowSystemAlert()
            sleep(1)
        }
        sleep(2)
        app.buttons["paywall.close"].tap()
        let feed = app.scrollViews["reader.feed"]
        XCTAssertTrue(app.buttons["reader.study"].waitForExistence(timeout: 30))
        sleep(2)
        for _ in 0..<3 { feed.swipeUp(velocity: .slow); sleep(2) }
        app.buttons["reader.save"].tap(); sleep(1)
        app.buttons["reader.study"].tap(); sleep(3)
        app.buttons["Done"].tap(); sleep(1)
        app.buttons["reader.passage"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("John 3:16"); sleep(1)
        app.buttons["passage.openReference"].tap()
        XCTAssertTrue(app.buttons["reader.verse.John|3|16"].waitForExistence(timeout: 30))
        sleep(3)
        feed.swipeUp(velocity: .slow); sleep(2)
        tab("Plans", in: app).tap(); sleep(2)
        app.buttons["plans.open.Gospel Tour"].tap(); sleep(3)
        app.buttons["Done"].tap(); sleep(1)
        tab("Saved", in: app).tap(); sleep(3)
    }

    /// Notification permission (daily reminder, trial heads-up) comes from SpringBoard, outside the app.
    private func allowSystemAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 1.5) { allow.tap() }
    }

    /// iPhone puts tabs in a tab bar; iPadOS 18+ shows them as a floating bar at the top.
    private func tab(_ name: String, in app: XCUIApplication) -> XCUIElement {
        let bar = app.tabBars.buttons[name]
        return bar.exists ? bar : app.buttons[name].firstMatch
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
