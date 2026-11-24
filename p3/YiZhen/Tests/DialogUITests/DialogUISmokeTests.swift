import XCTest

final class DialogUISmokeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testEmergencyBannerAppearsAndHides() {
        let emergency = app.buttons["dialog.scene.emergency"]
        XCTAssertTrue(emergency.waitForExistence(timeout: 10))
        emergency.tap()

        let banner = app.descendants(matching: .any)["dialog.emergencyBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))
        XCTAssertEqual(banner.label, "我听不见，请帮我打 120")

        app.buttons["dialog.scene.medical"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: banner)
        waitForExpectations(timeout: 2)
    }

    func testEmptyBaselineShowsEmptyState() {
        app.terminate()
        app.launchEnvironment["YZ_BASELINE"] = "empty"
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["dialog.empty"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["dialog.message.other.1.replay"].exists)
    }

    func testSegmentSwitchesContentAndReturns() {
        let phrases = app.buttons["dialog.segment.phrases"]
        XCTAssertTrue(phrases.waitForExistence(timeout: 10))
        phrases.tap()
        XCTAssertTrue(app.descendants(matching: .any)["dialog.phrase.list"].waitForExistence(timeout: 2))

        app.buttons["dialog.segment.dialog"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["dialog.message.other.1"].waitForExistence(timeout: 2))
    }

    func testSceneSwitchReplacesSecondaryNavigation() {
        let emergency = app.buttons["dialog.scene.emergency"]
        XCTAssertTrue(emergency.waitForExistence(timeout: 10))
        emergency.tap()

        XCTAssertTrue(app.buttons["dialog.phase.emergency.help"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["dialog.phase.medical.question"].exists)

        app.buttons["dialog.scene.medical"].tap()
        XCTAssertTrue(app.buttons["dialog.phase.medical.question"].waitForExistence(timeout: 2))
    }

    func testPhaseSwitchReplacesPhraseList() {
        app.buttons["dialog.segment.phrases"].tap()
        let register = app.buttons["dialog.phase.medical.register"]
        XCTAssertTrue(register.waitForExistence(timeout: 10))
        register.tap()

        XCTAssertTrue(
            app.buttons["dialog.phrase.row.medical.register.1"].waitForExistence(timeout: 2)
        )

        app.buttons["dialog.phase.medical.question"].tap()
        XCTAssertTrue(
            app.buttons["dialog.phrase.row.medical.question.1"].waitForExistence(timeout: 2)
        )
    }

    func testPlaceholderActionsShowToast() {
        let listen = app.buttons["dialog.action.listen"]
        XCTAssertTrue(listen.waitForExistence(timeout: 10))
        listen.tap()

        XCTAssertTrue(app.staticTexts["dialog.toast"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["dialog.toast"].label, "听写功能筹备中")


        app.buttons["dialog.action.fullscreen"].tap()
        XCTAssertTrue(app.staticTexts["全屏功能筹备中"].waitForExistence(timeout: 2))
    }

    func testPhraseRowShowsToastOnly() {
        app.buttons["dialog.segment.phrases"].tap()
        let row = app.buttons["dialog.phrase.row.medical.question.1"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.staticTexts["播报功能筹备中"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["共 6 条 · 点一句就能播"].label.isEmpty)
    }

    func testCardActionsShowToast() {
        let replay = app.buttons["dialog.message.other.1.replay"]
        XCTAssertTrue(replay.waitForExistence(timeout: 10))
        replay.tap()
        XCTAssertTrue(app.staticTexts["播报功能筹备中"].waitForExistence(timeout: 2))

        app.buttons["dialog.message.other.1.copy"].tap()
        XCTAssertTrue(app.staticTexts["复制功能筹备中"].waitForExistence(timeout: 2))
    }

    func testCardTapShowsPlaceholderToast() {
        let subject = app.descendants(matching: .any)["dialog.message.other.1"]
        XCTAssertTrue(subject.waitForExistence(timeout: 10))
        subject.tap()

        XCTAssertTrue(app.staticTexts["全屏大字牌筹备中"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["播报功能筹备中"].exists)
    }

    func testCardActionDoesNotTriggerCardTap() {
        let replay = app.buttons["dialog.message.other.1.replay"]
        XCTAssertTrue(replay.waitForExistence(timeout: 10))
        replay.tap()

        XCTAssertTrue(app.staticTexts["播报功能筹备中"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["全屏大字牌筹备中"].exists)

        app.buttons["dialog.message.other.1.copy"].tap()
        XCTAssertTrue(app.staticTexts["复制功能筹备中"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["全屏大字牌筹备中"].exists)
    }

    func testCardActionRowHitAreasMeetMinimumAndDoNotOverlap() {
        let replay = app.buttons["dialog.message.other.1.replay"]
        let copy = app.buttons["dialog.message.other.1.copy"]
        XCTAssertTrue(replay.waitForExistence(timeout: 10))
        XCTAssertTrue(copy.waitForExistence(timeout: 2))

        XCTAssertGreaterThanOrEqual(replay.frame.width, 44)
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        XCTAssertGreaterThanOrEqual(copy.frame.width, 44)
        XCTAssertGreaterThanOrEqual(copy.frame.height, 44)
        XCTAssertFalse(replay.frame.intersects(copy.frame))
        XCTAssertLessThanOrEqual(abs(replay.frame.maxX - copy.frame.minX), 0.5)
    }

    func testCardVerticalGapIsTwelve() {
        let otherCopy = app.buttons["dialog.message.other.1.copy"]
        let nextSubject = app.descendants(matching: .any)["dialog.message.mine.1"]
        XCTAssertTrue(otherCopy.waitForExistence(timeout: 10))
        XCTAssertTrue(nextSubject.waitForExistence(timeout: 2))

        let gap = nextSubject.frame.minY - otherCopy.frame.maxY - 32
        XCTAssertEqual(gap, 12, accuracy: 1)
    }

    func testMessageCardAccessibilityLabel() {
        let card = app.descendants(matching: .any)["dialog.message.other.1"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertTrue(card.label.contains("对方说"))
        XCTAssertTrue(card.label.contains("请问您哪里不舒服？"))
        XCTAssertTrue(card.label.contains("医生"))
        XCTAssertTrue(card.label.contains("09:41"))
        XCTAssertFalse(card.label.contains("已识别"))
    }

    func testSpeakOpensComposerAndCloses() {
        let speak = app.buttons["dialog.action.speak"]
        XCTAssertTrue(speak.waitForExistence(timeout: 10))
        speak.tap()

        XCTAssertTrue(app.staticTexts["dialog.composer.title"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["dialog.composer.title"].label, "我要说")
        XCTAssertTrue(app.textViews["dialog.composer.input"].exists)
        XCTAssertTrue(app.buttons["dialog.composer.send"].exists)

        app.buttons["dialog.composer.close"].tap()
        expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: app.buttons["dialog.composer.send"]
        )
        waitForExpectations(timeout: 2)
    }

    func testComposerEmptyDisablesSend() {
        app.buttons["dialog.action.speak"].tap()
        let send = app.buttons["dialog.composer.send"]
        XCTAssertTrue(send.waitForExistence(timeout: 2))
        XCTAssertFalse(send.isEnabled)
    }

    func testComposerSendAddsMessageAndKeepsDrawer() {
        app.buttons["dialog.action.speak"].tap()
        let input = app.textViews["dialog.composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 2))
        input.tap()
        input.typeText("请帮我写下来")

        let send = app.buttons["dialog.composer.send"]
        XCTAssertTrue(send.isEnabled)
        send.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["dialog.message.mine.c1"].waitForExistence(timeout: 2)
        )
        XCTAssertTrue(send.exists)
        XCTAssertEqual((input.value as? String) ?? "", "")
    }

    func testComposerEnterSends() {
        app.buttons["dialog.action.speak"].tap()
        let input = app.textViews["dialog.composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 2))
        input.tap()
        input.typeText("回车发送\n")

        XCTAssertTrue(
            app.descendants(matching: .any)["dialog.message.mine.c1"].waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.buttons["dialog.composer.send"].exists)
    }

    func testComposerCloseDiscardsDraft() {
        app.buttons["dialog.action.speak"].tap()
        let input = app.textViews["dialog.composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 2))
        input.tap()
        input.typeText("未发送草稿")
        let send = app.buttons["dialog.composer.send"]
        app.buttons["dialog.composer.close"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: send)
        waitForExpectations(timeout: 2)

        app.buttons["dialog.action.speak"].tap()
        XCTAssertTrue(app.textViews["dialog.composer.input"].waitForExistence(timeout: 2))
        XCTAssertEqual((app.textViews["dialog.composer.input"].value as? String) ?? "", "")
    }

    func testComposerNotesAreStaticText() {
        app.buttons["dialog.action.speak"].tap()
        XCTAssertTrue(app.staticTexts["听不清？可在「我的」打开全程用文字。"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["手语识别即将支持（占位）。"].exists)
    }

    func testInteractiveElementsMeetMinimumHitTarget() {
        let identifiers = [
            "dialog.faceToFace",
            "dialog.action.listen",
            "dialog.action.speak",
            "dialog.action.fullscreen",
            "dialog.message.other.1",
            "dialog.message.other.1.replay",
            "dialog.message.other.1.copy",
            "dialog.segment.dialog",
            "dialog.segment.phrases",
            "dialog.phase.medical.question"
        ]

        for identifier in identifiers {
            let element = app.descendants(matching: .any)[identifier]
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(identifier) 不存在")
            XCTAssertGreaterThanOrEqual(element.frame.width, 44, "\(identifier) 宽度不足 44")
            XCTAssertGreaterThanOrEqual(element.frame.height, 44, "\(identifier) 高度不足 44")
        }
    }
}