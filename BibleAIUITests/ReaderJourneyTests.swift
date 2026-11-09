import XCTest

/// Runs on a disposable simulator against the actual Bible provider and app persistence.
/// No provider stubs, test-user purchases, AI requests or production account mutations.
final class ReaderJourneyTests: XCTestCase {
    func testReadSaveNoteResumeAndSearch() throws {
        continueAfterFailure = false
        let app = launchReader()

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

        // An invitation can be read and swiped without replacing the personal bookmark.
        app.open(URL(string: "brightscroll://share?kind=verse&book=Psalms&chapter=23&verse=1&invite=c36c686f-09f1-40c2-b3a4-3df51cdd49d1")!)
        XCTAssertTrue(app.buttons["invitation.accept"].waitForExistence(timeout: 20))
        app.buttons["invitation.accept"].tap()
        XCTAssertTrue(app.buttons["reader.verse.Psalms|23|1"].waitForExistence(timeout: 15))
        app.scrollViews["reader.feed"].swipeUp()
        XCTAssertTrue(app.buttons["reader.returnToPlace"].exists)
        app.buttons["reader.passage"].tap()
        let beginning = app.buttons["passage.shortcut.Genesis|1|1"]
        XCTAssertTrue(beginning.waitForExistence(timeout: 5))
        beginning.tap()
        XCTAssertTrue(app.buttons["reader.verse.Genesis|1|1"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["reader.returnToPlace"].exists)
        app.terminate()
        app.launch()
        let restored = app.buttons["reader.verse.John|3|16"]
        XCTAssertTrue(restored.waitForExistence(timeout: 20) && restored.isHittable)
        try exerciseAllPlanPersistence(app)
        exerciseAccount(app)
    }

    func testPacedReadingAndPhraseSearch() throws {
        continueAfterFailure = false
        let app = launchReader() // first time choice is five minutes
        let today = app.buttons["reader.today"]
        XCTAssertTrue(today.waitForExistence(timeout: 8) && today.label.contains("Five Minutes in the Gospels"))
        today.tap()
        XCTAssertTrue(app.navigationBars["Matthew 1:20–21"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["chapter.reflection"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Next chapter"].exists)
        let finish = app.buttons["today.finish"]
        XCTAssertEqual(finish.label, "Finish today’s reading")
        capture("five-minute-passage-and-reflection")
        finish.tap()
        XCTAssertTrue(app.staticTexts["streak.title"].waitForExistence(timeout: 8))
        app.buttons["streak.done"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(today.waitForExistence(timeout: 12))
        XCTAssertTrue(today.label.contains("Day 2") && today.label.contains("1-day streak"))
        capture("returning-reader-streak")

        for (edition, phrase) in [("King James Version", "only begotten Son"), ("World English Bible", "one and only Son")] {
            app.buttons["reader.translation"].tap()
            app.buttons[edition].tap()
            app.buttons["reader.passage"].tap()
            let field = app.searchFields.firstMatch
            field.tap()
            field.typeText(phrase)
            let result = app.buttons["passage.result.John|3|16"]
            reveal(result, in: app)
            XCTAssertTrue(result.label.localizedCaseInsensitiveContains(phrase))
            result.tap()
            let verse = app.buttons["reader.verse.John|3|16"]
            let shown = NSPredicate(format: "isHittable == true AND label CONTAINS[c] %@", phrase)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: shown, evaluatedWith: verse)], timeout: 12), .completed)
            let back = app.buttons["reader.returnToPlace"]
            XCTAssertTrue(back.waitForExistence(timeout: 6))
            back.tap()
            XCTAssertTrue(app.buttons["reader.verse.Genesis|1|1"].waitForExistence(timeout: 10))
            XCTAssertFalse(back.exists)
        }
    }

    func testTodayTranslationAndStudyLibrary() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
        let passage = app.buttons["reader.passage"]
        XCTAssertTrue(passage.waitForExistence(timeout: 15))
        passage.tap()
        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText("John 3:16")
        let exact = app.buttons["passage.openReference"]
        XCTAssertTrue(exact.waitForExistence(timeout: 8))
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "exists == false"),
                            evaluatedWith: app.staticTexts["The Beginning"])], timeout: 5), .completed)
        exact.tap()
        let john = app.buttons["reader.verse.John|3|16"]
        let selectedVerse = NSPredicate(format: "isHittable == true AND label CONTAINS %@", "only begotten Son")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: selectedVerse, evaluatedWith: john)], timeout: 30), .completed)
        app.buttons["reader.translation"].tap()
        app.buttons["World English Bible"].tap()
        let web = NSPredicate(format: "isHittable == true AND label CONTAINS %@", "one and only Son")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: web, evaluatedWith: john)], timeout: 20), .completed)
        app.terminate()
        app.launch()
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: web, evaluatedWith: john)], timeout: 20), .completed)
        capture("reader-web-resume")
        app.buttons["Add a Note"].tap()
        let note = app.textViews["note.text"]
        note.tap()
        note.typeText("My WEB reading")
        app.buttons["note.save"].tap()
        tab("Saved", in: app).tap()
        let savedWeb = app.buttons["saved.verse.John|3|16|WEB"]
        XCTAssertTrue(savedWeb.waitForExistence(timeout: 8))
        XCTAssertTrue(savedWeb.label.contains("one and only Son") && savedWeb.label.contains("My WEB reading"))

        tab("Plans", in: app).tap()
        openPlan("Gospel Tour", in: app)
        let start = app.buttons["plan.start"]
        if !start.exists {
            app.buttons["Plan Options"].tap()
            app.buttons["Reset Progress"].tap()
            app.buttons["Reset Progress"].tap()
        }
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        app.buttons["Done"].tap()
        tab("The Bible", in: app).tap()
        let today = app.buttons["reader.today"]
        XCTAssertTrue(today.waitForExistence(timeout: 5) && today.label.contains("Day 1"))
        today.tap()
        let guide = app.buttons["chapter.guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 25))
        guide.tap()
        let save = app.buttons["study.save"]
        save.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "label == %@", "Study saved"), evaluatedWith: save)], timeout: 5), .completed)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Next chapter"].tap()
        XCTAssertTrue(app.navigationBars["Matthew 2"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["chapter.guide"].waitForExistence(timeout: 25))
        app.terminate()
        app.launch()
        today.tap()
        XCTAssertTrue(app.navigationBars["Matthew 2"].waitForExistence(timeout: 8))
        // Read the next chapter from the ordinary Plans list, then resume it through Today.
        app.buttons["today.close"].tap()
        tab("Plans", in: app).tap()
        openPlan("Gospel Tour", in: app)
        app.buttons["Luke 1"].firstMatch.tap()
        XCTAssertTrue(app.buttons["chapter.guide"].waitForExistence(timeout: 25))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Done"].tap()
        tab("The Bible", in: app).tap()
        today.tap()
        XCTAssertTrue(app.navigationBars["Luke 1"].waitForExistence(timeout: 15))
        for title in ["Luke 2"] {
            let next = app.buttons["Next chapter"]
            let enabled = NSPredicate(format: "isEnabled == true")
            XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: enabled, evaluatedWith: next)], timeout: 25), .completed)
            next.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 8))
        }
        let finish = app.buttons["today.finish"]
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: NSPredicate(format: "isEnabled == true"),
                          evaluatedWith: finish)], timeout: 25), .completed)
        finish.tap()
        XCTAssertTrue(app.staticTexts["streak.title"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(today.waitForExistence(timeout: 10) && today.label.contains("Day 2"))
        capture("today-next-reading")
        tab("Saved", in: app).tap()
        let saved = app.buttons["saved.study.Matthew|1|1"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5) && saved.label.contains("WEB"))
        saved.tap()
        XCTAssertTrue(app.staticTexts["study.body"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["study.body"].label.contains("Luke 1:26–33"))
        capture("saved-gospel-study")
        app.buttons["study.related"].tap()
        XCTAssertTrue(app.navigationBars["Luke 1:26–33"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["World English Bible"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["chapter.guide"].exists)
        capture("guide-related-passage-web")
        tab("The Bible", in: app).tap()
        app.buttons["reader.translation"].tap()
        app.buttons["King James Version"].tap()
        let kjv = NSPredicate(format: "isHittable == true AND label CONTAINS %@", "only begotten Son")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: kjv, evaluatedWith: john)], timeout: 20), .completed)
    }

    private func launchReader() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let next = app.buttons["onboarding.continue"]
        if app.buttons["reader.study"].waitForExistence(timeout: 2) { return app }
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

        return app
    }

    func testAppleSignInCancellation() {
        continueAfterFailure = false
        let app = launchReader()
        tab("Account", in: app).tap()
        exerciseAppleCancellation(app)
    }

    private func exerciseAccount(_ app: XCUIApplication) {
        let account = tab("Account", in: app)
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        account.tap()
        let subscription = app.buttons["account.subscription"]
        XCTAssertTrue(subscription.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["account.appleSignIn"].exists)
        XCTAssertFalse(app.buttons["account.signOut"].exists, "Do not invent a signed-in identity")
        XCTAssertTrue(app.descendants(matching: .any)["account.streak"].exists)
        capture("account-overview")
        reveal(subscription, in: app)
        subscription.tap()
        let status = app.staticTexts["subscription.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        let resolved = NSPredicate(format: "label != %@", "Checking subscription…")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: resolved, evaluatedWith: status)], timeout: 30), .completed)
        XCTAssertTrue(["Free plan", "Status unavailable"].contains(status.label),
                      "This disposable Simulator has no paid account; never invent a trial or payment")
        if status.label == "Status unavailable" {
            XCTAssertTrue(app.staticTexts["subscription.error"].exists)
        }
        XCTAssertTrue(app.buttons["subscription.manage"].exists)
        XCTAssertTrue(app.buttons["subscription.restore"].exists)
        reveal(app.buttons["subscription.history"], in: app)
        XCTAssertTrue(app.buttons["subscription.history"].isHittable)
        capture("account-subscription")
        // Exercise the real restore call on this disposable Simulator; never initiate a purchase.
        let restore = app.buttons["subscription.restore"]
        reveal(restore, in: app)
        restore.tap()
        let result = app.alerts["Restore Purchases"]
        let pending = app.staticTexts["subscription.restorePending"]
        let feedback = NSPredicate { _, _ in result.exists || pending.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: feedback, evaluatedWith: app)], timeout: 25), .completed,
                       "Restore must explain a long wait, not leave only a spinner")
        if result.exists {
            XCTAssertFalse(result.staticTexts["Your Premium access has been restored."].exists)
            capture("account-restore-result")
            result.buttons["OK"].tap()
        } else {
            XCTAssertTrue(pending.label.contains("You can keep reading"))
            XCTAssertFalse(restore.isEnabled, "Do not allow duplicate restores while the first is pending")
            XCTAssertEqual(status.label, "Free plan", "Pending restore must not claim Premium")
            capture("account-restore-pending")
            print("RESTORE_BOUNDARY StoreKit still pending; paid restoration remains unverified")
        }
        app.navigationBars.buttons.firstMatch.tap()
        let readingSettings = app.buttons["account.settings"]
        reveal(readingSettings, in: app)
        readingSettings.tap()
        XCTAssertTrue(app.sliders["settings.textSize"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        tab("Saved", in: app).tap()
        assertSavedNote(app, equals: "A quiet moment with Scripture.")
        tab("Account", in: app).tap()
        print("INTERACTION_ASSERTED account.subscription.settings.restore")
    }

    private func exerciseAppleCancellation(_ app: XCUIApplication) {
        for _ in 0..<3 { app.swipeDown() }
        let signIn = app.buttons["account.appleSignIn"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
        signIn.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let authError = app.staticTexts["account.authError"]
        let cancel = app.buttons["Cancel"].firstMatch
        let systemCancel = springboard.buttons["Cancel"].firstMatch
        let close = app.buttons["Close"].firstMatch
        let systemClose = springboard.buttons["Close"].firstMatch
        let appleResponse = NSPredicate { _, _ in
            authError.exists || cancel.exists || systemCancel.exists || close.exists || systemClose.exists
        }
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: appleResponse, evaluatedWith: app)], timeout: 20), .completed,
                       "The real Apple request must respond or present a cancellable sheet")
        capture("account-apple-signin-response")
        if cancel.exists { cancel.tap() }
        else if systemCancel.exists { systemCancel.tap() }
        else if close.exists { close.tap() }
        else if systemClose.exists { systemClose.tap() }
        let ready = NSPredicate(format: "exists == true AND enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: ready, evaluatedWith: signIn)], timeout: 8), .completed)
        XCTAssertFalse(app.buttons["account.signOut"].exists,
                       "A canceled/unsupported Simulator authorization must not create a session")
        print("INTERACTION_ASSERTED account.appleCancellation")
        print("APPLE_BOUNDARY Signed Apple login and sign-out still require an authenticated physical device")
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
        tab("The Bible", in: app).tap()
        let today = app.buttons["reader.today"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(today.label.contains("Proverbs Wisdom") && today.label.contains("Day 2"))
        today.tap()
        XCTAssertTrue(app.navigationBars["Proverbs 2"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["today.finish"].waitForExistence(timeout: 15))
        app.buttons["today.close"].tap()
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

    /// Real system share sheet + a received invitation before the ordinary onboarding funnel.
    func testZShareAndInvitationJourney() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "NO"]
        app.launch()
        let openInvite = app.buttons["onboarding.openInvitation"]
        XCTAssertTrue(openInvite.waitForExistence(timeout: 10))
        openInvite.tap()
        let entry = app.descendants(matching: .any)["invitation.link"].firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        entry.tap()
        let invalid = "https://example.com/"
        entry.typeText(invalid)
        app.buttons["invitation.open"].tap()
        XCTAssertTrue(app.staticTexts["invitation.invalid"].waitForExistence(timeout: 3))
        entry.tap()
        entry.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: invalid.count))
        entry.typeText("https://www.bibleaicompanion.com/share?kind=verse&book=John&chapter=3&verse=16&invite=850b0200-1275-4dad-a5a1-ae7cb4090ce1")
        app.buttons["invitation.open"].tap()
        let invitation = app.staticTexts["invitation.verse"]
        XCTAssertTrue(invitation.waitForExistence(timeout: 30))
        XCTAssertTrue(invitation.label.contains("For God so loved the world"))
        XCTAssertFalse(app.buttons["paywall.close"].exists)
        capture("growth-recipient-verse")
        app.buttons["invitation.accept"].tap()
        let verse = app.buttons["reader.verse.John|3|16"]
        XCTAssertTrue(verse.waitForExistence(timeout: 15))
        XCTAssertTrue(verse.isHittable)
        app.buttons["reader.share"].tap()
        XCTAssertTrue(app.buttons["share.send"].waitForExistence(timeout: 5))
        capture("growth-share-paper")
        let night = app.buttons["Night"]
        XCTAssertTrue(night.exists)
        night.tap()
        capture("growth-share-night")
        app.buttons["share.send"].tap()
        // iOS26 exposes system share actions as collection cells (observed in the failing run).
        let copy = app.cells["Copy"].firstMatch
        XCTAssertTrue(copy.waitForExistence(timeout: 10), "Real iOS share sheet must offer Copy")
        let caption = app.otherElements["LP.CaptionBar.BottomCaption"]
        XCTAssertTrue(caption.label.contains("For God so loved the world"))
        XCTAssertTrue(caption.label.contains("https://www.bibleaicompanion.com/share?kind=verse&book=John&chapter=3&verse=16&invite="))
        capture("growth-system-share")
        copy.tap()
        let completed = app.staticTexts["share.status"]
        XCTAssertTrue(completed.waitForExistence(timeout: 5))
        XCTAssertEqual(completed.label, "Share activity completed.")
        XCTAssertTrue(app.buttons["share.close"].waitForExistence(timeout: 5))
        app.buttons["share.close"].tap()
        // The system Close path must remain usable and must not count as a completed activity.
        app.buttons["reader.share"].tap()
        app.buttons["share.send"].tap()
        let closeActivity = app.buttons["header.closeButton"]
        XCTAssertTrue(closeActivity.waitForExistence(timeout: 5))
        closeActivity.tap()
        XCTAssertTrue(app.buttons["share.close"].waitForExistence(timeout: 5))
        app.buttons["share.close"].tap()
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["reader.verse.John|3|16"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["onboarding.continue"].exists)
        tab("Plans", in: app).tap()
        app.open(URL(string: "brightscroll://share?kind=plan&plan=6f1c2a10-0001-4b1a-9e1e-0000000000a1&invite=3d8eed79-247b-4b3b-8f10-8cd3a30bf2e7")!)
        XCTAssertTrue(app.staticTexts["invitation.plan"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["invitation.plan"].label, "Gospel Tour")
        capture("growth-recipient-plan")
        app.buttons["invitation.accept"].tap()
        XCTAssertTrue(app.buttons["plan.invite"].waitForExistence(timeout: 5))
        app.buttons["plan.invite"].tap()
        XCTAssertTrue(app.buttons["share.send"].waitForExistence(timeout: 5))
        capture("growth-plan-invitation")
        app.buttons["share.send"].tap()
        let planCopy = app.cells["Copy"].firstMatch
        XCTAssertTrue(planCopy.waitForExistence(timeout: 10))
        capture("growth-plan-system-share")
        planCopy.tap()
        XCTAssertTrue(app.staticTexts["share.status"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["share.status"].label, "Share activity completed.")
        app.buttons["share.close"].tap()
        let chapter = app.buttons["Matthew 1"].firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 5))
        chapter.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "The book of the generation of Jesus Christ")).firstMatch.waitForExistence(timeout: 30))
        capture("growth-plan-reading")
        print("GROWTH_ASSERTED invalid-link exact-verse onboarding-bypass share-sheet copy plan-invite real-chapter relaunch")
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
