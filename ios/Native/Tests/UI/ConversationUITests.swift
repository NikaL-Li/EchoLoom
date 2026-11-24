import XCTest

final class PlaybackProgressUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "com.ylct.universal")
    }
    private func launch(face: Bool = false, appearance: String = "light") {
        app.launchArguments = ["--review-screen", "dialogue", "--test-custom-phrases", "success", "--reset-test-custom-phrases", "-ylct.appearance", appearance]
        if face { app.launchArguments.append("--review-listen") }
        app.launch()
        XCTAssertTrue(app.buttons[face ? "conversation.listen" : "call.status"].waitForExistence(timeout: 12))
    }
    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
    private func waitForValue(_ element: XCUIElement, containing text: String, timeout: TimeInterval = 15) {
        let predicate = NSPredicate(format: "value CONTAINS %@", text)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout), .completed)
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testPresetProgressCompletionAndReplayReset() {
        launch()
        let phrase = app.buttons["phrases.quick.builtin.请再说一遍，慢一点，谢谢。"]
        XCTAssertTrue(phrase.waitForExistence(timeout: 5))
        let originalHeight = phrase.frame.height
        phrase.tap()
        waitForValue(phrase, containing: "正在播报", timeout: 3)
        let pinned = element("playback.quick.pinned")
        XCTAssertTrue(pinned.exists)
        XCTAssertEqual(phrase.frame.height, originalHeight, accuracy: 1, "Playing only changes the background fill, not card height")
        XCTAssertEqual(app.staticTexts.matching(identifier: "正在播报").count, 1, "Only the pinned transport shows detailed playback status")
        XCTAssertFalse(element("playback.quick.detail").exists, "The last-spoken card does not duplicate progress")
        XCTAssertTrue((pinned.value as? String ?? "").contains("/"), "Bundled audio reports its real duration")
        capture("01-常用语按钮叠加进度")
        waitForValue(phrase, containing: "播报结束")
        XCTAssertFalse(app.buttons["playback.quick.stop"].exists)
        phrase.tap()
        waitForValue(phrase, containing: "正在播报", timeout: 3)
        app.buttons["playback.quick.stop"].tap()
        waitForValue(phrase, containing: "已停止")
        capture("02-停止后保留进度")
    }
    func testSwitchingPresetCannotCompleteTheNewPlayback() {
        launch(appearance: "dark")
        let first = app.buttons["phrases.quick.builtin.餐放门口了，麻烦您取一下"]
        let next = app.buttons["phrases.quick.builtin.我在小区门口，马上到"]
        first.tap(); waitForValue(first, containing: "正在播报", timeout: 3)
        next.tap(); waitForValue(next, containing: "正在播报", timeout: 3)
        XCTAssertEqual(first.value as? String, "尚未播报", "Only the actual current shortcut carries the live overlay")
        capture("03-深色常用语切换进度")
        waitForValue(next, containing: "播报结束")
        XCTAssertFalse(app.buttons["playback.quick.stop"].exists)
    }
    func testSystemSpeechProgressStopsAndReplaysInTheSameBubble() {
        launch(face: true)
        let draft = element("conversation.draft")
        draft.tap(); draft.typeText("您好，请在小区东门等我。我正在确认送达地址，马上回来，谢谢您的理解。")
        app.buttons["conversation.send"].tap()
        let pinned = element("playback.face.pinned")
        XCTAssertTrue(pinned.waitForExistence(timeout: 5))
        waitForValue(pinned, containing: "系统语音", timeout: 5)
        XCTAssertFalse((pinned.value as? String ?? "").contains("/"), "Direct system speech starts without rendering the full sentence or guessing duration")
        capture("04-面对面系统直接播报")
        app.buttons["停止播报"].firstMatch.tap()
        waitForValue(pinned, containing: "已停止")
        XCTAssertTrue(app.staticTexts["麦克风已暂停"].exists)
        app.buttons["重播"].firstMatch.tap()
        waitForValue(pinned, containing: "正在播报", timeout: 5)
        waitForValue(pinned, containing: "播报结束", timeout: 40)
        XCTAssertEqual(app.buttons.matching(identifier: "重播").count, 1)
        capture("05-播报结束与历史气泡")
    }
    func testPreviewProgressFollowsTheChosenVoice() {
        launch()
        app.buttons["phrases.manage"].tap()
        app.buttons["phrases.add"].tap()
        let text = app.textFields["phrases.editor-text"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap(); text.typeText("请在东门稍等，我马上到。")
        app.buttons["phrases.dismiss-keyboard"].tap()
        app.buttons["phrases.generate"].tap()
        let female = app.buttons["试听女声"], male = app.buttons["试听男声"]
        XCTAssertTrue(female.waitForExistence(timeout: 10))
        let previewHeight = female.frame.height
        female.tap(); waitForValue(female, containing: "正在播报", timeout: 3)
        XCTAssertEqual(female.frame.height, previewHeight, accuracy: 1, "Voice preview buttons remain compact during playback")
        male.tap(); waitForValue(male, containing: "正在播报", timeout: 3)
        XCTAssertEqual(female.value as? String, "尚未播报")
        XCTAssertTrue(element("playback.preview.pinned").exists)
        capture("06-双声试听按钮进度")
        waitForValue(male, containing: "播报结束")
    }
    func testQuickRepliesRemainVisibleWithKeyboardAndTypedTextUsesSystemSpeech() {
        launch(face: true)
        let text = "请再说一遍，慢一点，谢谢。"
        let shortcut = app.buttons["phrases.face.builtin.\(text)"]
        XCTAssertTrue(shortcut.isHittable, "Replies are directly visible without expanding a disclosure")
        XCTAssertFalse(app.buttons["常用回复"].exists)
        let draft = element("conversation.draft")
        draft.tap(); draft.typeText(text)
        XCTAssertTrue(shortcut.isHittable, "Replies remain above the input while the keyboard is open")
        XCTAssertTrue(app.buttons["phrases.manage"].isHittable)
        capture("07-键盘打开常用回复常驻")
        app.buttons["conversation.send"].tap()
        let pinned = element("playback.face.pinned")
        waitForValue(pinned, containing: "系统语音", timeout: 5)
        XCTAssertEqual(shortcut.value as? String, "尚未播报", "Typing a matching phrase does not activate its shortcut")
        waitForValue(pinned, containing: "播报结束", timeout: 20)
        shortcut.tap()
        waitForValue(pinned, containing: "/", timeout: 5)
        waitForValue(shortcut, containing: "正在播报", timeout: 3)
        capture("08-常用回复MiMo本地音频进度")
        waitForValue(pinned, containing: "播报结束", timeout: 20)
    }
    func testEveryFaceReplyPlaysOfflineWithoutFirstUseGeneration() {
        for voice in ["male", "female"] {
            app.terminate()
            app.launchArguments = ["--review-screen", "dialogue", "--review-listen", "--test-custom-phrases", "offline", "--reset-test-custom-phrases", "-ylct.voiceGender", voice]
            app.launch()
            for text in ["请再说一遍，慢一点，谢谢。", "请稍等，我正在打字。", "好的，谢谢！"] {
                let shortcut = app.buttons["phrases.face.builtin.\(text)"]
                XCTAssertTrue(shortcut.waitForExistence(timeout: 12))
                let strip = app.scrollViews["conversation.quick-reply-scroll"]
                for _ in 0..<3 where !shortcut.isHittable { strip.swipeLeft() }
                XCTAssertTrue(shortcut.isHittable)
                XCTAssertTrue(shortcut.isEnabled)
                shortcut.tap()
                // Check this exact button, never the previous reply's completed
                // pinned status. A failed tap cannot count as a successful play.
                waitForValue(shortcut, containing: "/", timeout: 5)
                waitForValue(shortcut, containing: "播报结束", timeout: 20)
            }
        }
        capture("09-全新离线打开即可播放男女声")
    }
}

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "com.ylct.universal")
    }
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func page(_ index: Int) {
        XCTAssertTrue(app.staticTexts["onboarding.title.\(index)"].waitForExistence(timeout: 10))
        if !app.buttons["onboarding.next"].isHittable {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Guide element hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
            capture("引导按钮诊断")
        }
        XCTAssertTrue(app.buttons["onboarding.next"].isHittable)
    }
    func launchFirst() {
        app.launchArguments = ["--test-first-launch", "-ylct.appearance", "light"]
        app.launch(); page(0)
    }
    func launchNormally() {
        app.terminate(); app.launchArguments = []; app.launch()
    }
    // A hittable button and a valid PNG in the IPA do not prove that pixels were drawn.
    private func checkCaptionPixels(_ step: Int) throws {
        let button = app.descendants(matching: .any).matching(identifier: "captions.viewport").firstMatch
        let landed = NSPredicate(format: "value == %@", "已标出按钮")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: landed, object: button)], timeout: 7), .completed)
        let image = try XCTUnwrap(button.screenshot().image.cgImage)
        XCTAssertGreaterThan(min(image.width, image.height), 180)
        let w = 320, h = 150
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            let ctx = CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8,
                bytesPerRow: w*4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        var outlines = 0
        for i in stride(from: 0, to: rgba.count, by: 4) {
            let r = Int(rgba[i]), g = Int(rgba[i + 1]), b = Int(rgba[i + 2])
            if r < 180 && g > 190 && b > 150 && g - r > 50 { outlines += 1 }
        }
        XCTAssertGreaterThan(outlines, 160, "Slide \(step) must show the marked tap target")
    }
    func testOnboardingAllCaptionImagesAreDrawn() throws {
        launchFirst()
        app.buttons["onboarding.step.2"].tap(); page(2)
        for i in 0..<4 {
            app.buttons["captions.step.\(i)"].tap()
            try checkCaptionPixels(i)
            capture("译声聚焦引导-\(i+1)")
        }
    }
    func testCompleteAndReplay() {
        launchFirst()
        XCTAssertEqual(app.alerts.count, 0)
        app.buttons["onboarding.tryReply"].tap()
        XCTAssertTrue(app.staticTexts["我约了下午三点，谢谢。"].exists)
        capture("译声-面对面引导")
        app.buttons["onboarding.next"].tap(); page(1)
        app.buttons["onboarding.demoNavigate"].tap()
        XCTAssertTrue(app.staticTexts["先核对目的地，再选择地图导航。"].exists)
        app.buttons["onboarding.next"].tap(); page(2)
        XCTAssertEqual(app.buttons["onboarding.next"].label, "下次再说")
        XCTAssertTrue(app.buttons["captions.settings"].isHittable)
        capture("译声-实时字幕引导")
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.buttons["universal.phone"].waitForExistence(timeout: 8))
        launchNormally()
        app.buttons["home.more"].tap()
        app.buttons["tab.我的"].tap()
        app.buttons["account.onboarding"].tap(); page(0)
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["account.onboarding"].waitForExistence(timeout: 5))
    }
    func testSettingsRoundTripAndPhoneTutorial() throws {
        launchFirst()
        app.buttons["onboarding.step.2"].tap(); page(2)
        app.buttons["captions.settings"].tap()
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10))
        let attachment = XCTAttachment(screenshot: settings.screenshot())
        attachment.name = "系统设置实际落点"; attachment.lifetime = .keepAlways; add(attachment)
        app.activate(); page(2)
        XCTAssertEqual(app.buttons["onboarding.next"].label, "完成引导")
        app.buttons["onboarding.next"].tap()
        app.buttons["universal.phone"].tap()
        app.buttons["phone.captions"].tap()
        XCTAssertTrue(app.navigationBars["系统实时字幕"].waitForExistence(timeout: 5))
        app.buttons["captions.step.1"].tap()
        XCTAssertTrue(app.buttons["captions.step.1"].isSelected)
        app.buttons["captions.enlarge"].tap()
        XCTAssertTrue(app.navigationBars["查看标注图"].waitForExistence(timeout: 5))
        let transport = app.buttons["captions.transport"]
        if transport.label == "重播" { transport.tap() }
        transport.tap()
        XCTAssertEqual(transport.label, "继续")
        transport.tap()
        print("YS273_MOVIE_START")
        app.buttons["captions.detail.step.2"].tap()
        XCTAssertTrue(app.staticTexts["captions.title"].label.contains("打开实时字幕开关"))
        let stage = app.descendants(matching: .any).matching(identifier: "captions.viewport").firstMatch
        XCTAssertEqual(stage.value as? String, "查看页面")
        capture("全屏演示初始")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "已标出按钮"), object: stage)], timeout: 7), .completed)
        capture("全屏演示定位")
        app.buttons["captions.detail.advance"].tap()
        XCTAssertTrue(app.staticTexts["captions.title"].label.contains("iPhone 音频"))
        app.buttons["captions.closeImage"].tap()
        XCTAssertTrue(app.buttons["captions.step.3"].isSelected)
        try checkCaptionPixels(3)
        capture("译声-电话辅助字幕教程")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["phone.captions"].waitForExistence(timeout: 5))
    }
    func testDarkReplayPreservesDraft() {
        app.launchArguments = ["--review-screen", "dialogue", "--review-listen", "-ylct.appearance", "dark"]
        app.launch()
        let draft = app.descendants(matching: .any).matching(identifier: "conversation.draft").firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 10))
        draft.tap(); draft.typeText("下午见")
        app.buttons["收起键盘"].tap(); app.buttons["关闭"].tap()
        app.buttons["home.more"].tap(); app.buttons["tab.我的"].tap()
        app.buttons["account.onboarding"].tap(); page(0)
        app.buttons["onboarding.step.2"].tap(); page(2)
        capture("译声-深色字幕教程")
        app.buttons["onboarding.next"].tap()
        app.buttons["tab.沟通"].tap(); app.buttons["universal.face"].tap()
        XCTAssertEqual(draft.value as? String, "下午见")
    }
    func testInterruptedGuideAndSkipPersistence() {
        launchFirst()
        app.buttons["onboarding.next"].tap(); page(1)
        launchNormally(); page(0)
        app.buttons["onboarding.next"].tap(); page(1)
        app.buttons["onboarding.back"].tap(); page(0)
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["universal.face"].waitForExistence(timeout: 8))
        launchNormally()
        XCTAssertTrue(app.buttons["universal.face"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboarding.skip"].exists)
    }

}

final class ConversationUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "com.ylct.universal")
        app.launchArguments = ["--review-screen", "dialogue", "--review-listen", "-ylct.appearance", "light"]
        app.launch()
        XCTAssertTrue(app.buttons["conversation.listen"].waitForExistence(timeout: 15))
    }
    func field(_ id: String) -> XCUIElement { app.descendants(matching: .any).matching(identifier: id).firstMatch }
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testReplyPlaybackDraftAndHistorySurviveNavigation() {
        XCTAssertTrue(app.staticTexts["麦克风已暂停"].exists)
        XCTAssertFalse(app.buttons["conversation.send"].isEnabled)
        capture("01-空白对话")
        let draft = field("conversation.draft")
        draft.tap(); draft.typeText("好的，我在东门等您。")
        app.buttons["conversation.send"].tap()
        XCTAssertTrue(app.staticTexts["好的，我在东门等您。"].waitForExistence(timeout: 5))
        let finished = app.staticTexts["播报结束"].firstMatch
        XCTAssertTrue(finished.waitForExistence(timeout: 25))
        XCTAssertTrue(app.staticTexts["麦克风已暂停"].exists, "Sending without starting listening must not enable microphone")
        capture("02-输入回复并播报结束")
        let replay = app.buttons["重播"].firstMatch
        replay.tap()
        XCTAssertTrue(finished.waitForExistence(timeout: 25))
        XCTAssertEqual(app.staticTexts.matching(identifier: "好的，我在东门等您。").count, 1)
        draft.tap(); draft.typeText("这句尚未发送")
        app.buttons["收起键盘"].tap()
        app.buttons["不出声，放大给对方看"].tap()
        XCTAssertTrue(app.staticTexts["这句尚未发送"].waitForExistence(timeout: 5))
        capture("03-无声大字展示")
        app.buttons["返回对话"].tap()
        XCTAssertEqual(field("conversation.draft").value as? String, "这句尚未发送")
        app.buttons["关闭"].tap()
        app.buttons["home.chat"].tap()
        XCTAssertTrue(app.buttons["conversation.send"].waitForExistence(timeout: 8))
        XCTAssertEqual(field("conversation.draft").value as? String, "这句尚未发送")
        XCTAssertTrue(app.staticTexts["好的，我在东门等您。"].exists)
    }
    func testPartnerTypingClearAndOfflinePreset() {
        app.buttons["请对方打字"].tap()
        XCTAssertTrue(app.staticTexts["请直接打字回复我"].waitForExistence(timeout: 5))
        let input = field("conversation.partner-draft")
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("请从东门进来，门牌是1502。")
        app.buttons["交给我"].tap()
        XCTAssertTrue(app.staticTexts["请从东门进来，门牌是1502。"].waitForExistence(timeout: 5))
        capture("04-对方文字回复")
        app.buttons["对话设置"].tap()
        app.buttons["清空本次对话"].tap()
        app.buttons["清空本次对话"].tap()
        XCTAssertTrue(app.staticTexts["你打字，我来说"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["请从东门进来，门牌是1502。"].exists)
        app.buttons["先介绍自己"].tap()
        XCTAssertTrue(app.staticTexts["播报结束"].firstMatch.waitForExistence(timeout: 25))
        capture("05-本机常用语完成")
    }
    func testStopSpeechIsVisibleAndDoesNotStartMicrophone() {
        let input = field("conversation.draft")
        input.tap(); input.typeText("请稍等，我正在确认订单。请稍等，我正在确认订单。请稍等，我正在确认订单。请稍等，我正在确认订单。")
        app.buttons["conversation.send"].tap()
        let stop = app.buttons["停止播报"]
        XCTAssertTrue(stop.waitForExistence(timeout: 8)); stop.tap()
        XCTAssertTrue(app.staticTexts["已停止 · 可重播"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["麦克风已暂停"].exists)
        XCTAssertTrue(app.buttons["重播"].firstMatch.isEnabled)
        capture("06-中断可恢复")
    }
    func testConversationInLightDarkAndLargeText() {
        for (name, appearance, large) in [("07-浅色双向消息", "light", false), ("08-深色双向消息", "dark", false), ("09-大字体双向消息", "light", true)] {
            app.terminate()
            app.launchArguments = ["--review-screen", "dialogue", "--review-listen", "-ylct.appearance", appearance]
            if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"] }
            app.launch()
            XCTAssertTrue(app.buttons["请对方打字"].waitForExistence(timeout: 12))
            app.buttons["请对方打字"].tap()
            let partner = field("conversation.partner-draft")
            XCTAssertTrue(partner.waitForExistence(timeout: 5)); partner.tap(); partner.typeText("餐还要五分钟，请在右侧取餐口等一下。")
            app.buttons["交给我"].tap()
            let draft = field("conversation.draft")
            XCTAssertTrue(draft.waitForExistence(timeout: 5)); draft.tap(); draft.typeText("好的，出餐后请挥手示意我，谢谢。")
            XCTAssertTrue(app.staticTexts["餐还要五分钟，请在右侧取餐口等一下。"].isHittable, "Keep the partner reply visible while composing")
            capture(name + "-键盘输入")
            app.buttons["conversation.send"].tap()
            XCTAssertTrue(app.staticTexts["播报结束"].firstMatch.waitForExistence(timeout: 25))
            capture(name)
        }
    }

}

final class DeliveryFlowUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() { continueAfterFailure = false; app = XCUIApplication(bundleIdentifier: "com.ylct.universal") }
    func launch(_ screen: String = "delivery", large: Bool = false) {
        app.launchArguments = ["--review-screen", screen, "--test-external-links", "-ylct.appearance", "light"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"] }
        app.launch()
    }
    func field(_ id: String) -> XCUIElement { app.descendants(matching: .any).matching(identifier: id).firstMatch }
    func fill(_ id: String, _ value: String) {
        let element = field(id)
        XCTAssertTrue(element.waitForExistence(timeout: 8))
        for _ in 0..<5 {
            let lowerEdge = app.keyboards.firstMatch.exists ? app.keyboards.firstMatch.frame.minY - 70 : app.buttons["delivery.continue"].exists ? app.buttons["delivery.continue"].frame.minY - 90 : app.frame.maxY - 60
            if element.isHittable && element.frame.midY > 160 && element.frame.midY < lowerEdge { break }
            let form = app.scrollViews["delivery.form"]
            if !form.exists { break }
            if element.frame.midY < 160 { form.swipeDown() } else { form.swipeUp() }
        }
        element.tap(); element.typeText(value)
    }
    func finishEditing() { app.buttons["完成"].tap() }
    func capture(_ name: String) { let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a) }
    func testHomeFaceToFaceCannotChangeDeliveryDefaultOrDraft() {
        launch("home")
        XCTAssertTrue(app.buttons["home.chat"].waitForExistence(timeout: 12)); app.buttons["home.chat"].tap()
        fill("conversation.draft", "首页的未发回复")
        app.buttons["收起键盘"].tap(); app.buttons["关闭"].tap()
        app.buttons["home.delivery"].tap()
        fill("delivery.address", "杭州市西湖区文三路测试小区")
        fill("delivery.room", "1502")
        fill("delivery.note", "放门口，请勿敲门")
        finishEditing()
        app.buttons["delivery.continue"].tap()
        XCTAssertTrue(app.buttons["电话沟通"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["电话沟通"].isSelected)
        XCTAssertTrue(field("delivery.context-address").exists)
        XCTAssertTrue(field("delivery.context-note").exists)
        capture("01-订单电话沟通")
        app.buttons["delivery.address-question"].tap()
        XCTAssertTrue((field("dialogue.quick-draft").value as? String ?? "").contains("1502室"))
        finishEditing()
        app.buttons["面对面聊天"].tap()
        XCTAssertTrue(app.buttons["conversation.listen"].waitForExistence(timeout: 5))
        XCTAssertNotEqual(field("conversation.draft").value as? String, "首页的未发回复")
        fill("conversation.draft", "这一单的现场回复")
        app.buttons["收起键盘"].tap()
        XCTAssertTrue(field("delivery.context-disclosure").exists)
        capture("02-面对面保留订单提示")
        app.buttons["关闭"].tap(); app.buttons["home.chat"].tap()
        XCTAssertTrue(app.buttons["conversation.listen"].waitForExistence(timeout: 5))
        XCTAssertEqual(field("conversation.draft").value as? String, "首页的未发回复")
        XCTAssertFalse(field("delivery.context-disclosure").exists)
        app.buttons["关闭"].tap(); app.buttons["home.delivery"].tap()
        XCTAssertTrue(app.buttons["delivery.continue"].waitForExistence(timeout: 5)); app.buttons["delivery.continue"].tap()
        XCTAssertTrue(app.buttons["电话沟通"].waitForExistence(timeout: 5)); XCTAssertTrue(app.buttons["电话沟通"].isSelected)
        XCTAssertTrue((field("dialogue.quick-draft").value as? String ?? "").contains("1502室"))
        app.buttons["面对面聊天"].tap()
        XCTAssertEqual(field("conversation.draft").value as? String, "这一单的现场回复")
    }
    func testNavigationPreviewAndConfirmedPhoneHandoff() {
        launch()
        fill("delivery.address", "杭州市西湖区西湖")
        fill("delivery.room", "1502")
        fill("delivery.phone", "13800000000")
        fill("delivery.note", "放门口，请勿敲门")
        finishEditing()
        XCTAssertTrue(app.buttons["delivery.navigate"].isEnabled)
        XCTAssertTrue(app.buttons["delivery.call"].isEnabled)
        XCTAssertGreaterThanOrEqual(app.buttons["delivery.continue"].frame.minY - app.buttons["delivery.call"].frame.maxY, 8)
        capture("03-地址页分离导航电话与主操作")
        app.buttons["delivery.navigate"].tap()
        XCTAssertTrue(field("delivery.map-query").waitForExistence(timeout: 5))
        XCTAssertEqual(field("delivery.map-query").value as? String, "杭州市西湖区西湖")
        capture("04-导航前核对地址")
        app.buttons["delivery.open-map"].tap()
        XCTAssertTrue(app.alerts["地图提示"].waitForExistence(timeout: 5))
        let mapText = app.alerts.staticTexts.allElementsBoundByIndex.map(\.label).joined()
        XCTAssertTrue(mapText.contains("maps.apple.com/directions")); XCTAssertTrue(mapText.contains("mode=cycling")); XCTAssertFalse(mapText.contains("1502"))
        app.buttons["知道了"].tap(); app.buttons["返回订单"].tap()
        XCTAssertTrue(app.buttons["delivery.call"].waitForExistence(timeout: 5)); app.buttons["delivery.call"].tap()
        XCTAssertTrue(app.buttons["进入沟通并拨号"].waitForExistence(timeout: 5))
        capture("05-拨号前核对号码")
        app.buttons["取消"].tap()
        XCTAssertTrue(app.buttons["delivery.continue"].exists, "Cancelling must keep the order form")
        app.buttons["delivery.call"].tap(); app.buttons["进入沟通并拨号"].tap()
        XCTAssertTrue(app.alerts["电话提示"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.alerts.staticTexts.allElementsBoundByIndex.map(\.label).joined().contains("tel:13800000000"))
        app.buttons["知道了"].tap()
        XCTAssertTrue(app.buttons["电话沟通"].isSelected)
        app.buttons["dialogue.call-customer"].tap()
        XCTAssertTrue(app.alerts["核对顾客号码"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["拨打 13800000000"].exists)
        app.buttons["取消"].tap()
        app.buttons["dialogue.return-address"].tap()
        XCTAssertTrue(app.buttons["delivery.continue"].waitForExistence(timeout: 8))
        XCTAssertEqual(field("delivery.address").value as? String, "杭州市西湖区西湖")
        XCTAssertEqual(field("delivery.phone").value as? String, "13800000000")
    }
    func testAddressQuestionRefreshKeepsUserEdits() {
        launch()
        fill("delivery.address", "杭州市西湖区测试小区")
        finishEditing(); app.buttons["delivery.continue"].tap()
        XCTAssertTrue(app.buttons["delivery.address-question"].waitForExistence(timeout: 8))
        app.buttons["delivery.address-question"].tap(); finishEditing()
        app.buttons["dialogue.return-address"].tap()
        fill("delivery.building", "B")
        finishEditing(); app.buttons["delivery.continue"].tap()
        XCTAssertTrue(app.buttons["电话沟通"].waitForExistence(timeout: 8))
        XCTAssertTrue((field("dialogue.quick-draft").value as? String ?? "").contains("B栋"))
        fill("dialogue.quick-draft", "请用短信回复，谢谢。")
        let edited = field("dialogue.quick-draft").value as? String
        finishEditing(); app.buttons["dialogue.return-address"].tap()
        fill("delivery.room", "1502")
        finishEditing(); app.buttons["delivery.continue"].tap()
        XCTAssertTrue(app.buttons["电话沟通"].waitForExistence(timeout: 8))
        XCTAssertEqual(field("dialogue.quick-draft").value as? String, edited, "Address edits must not replace user-authored text")
        XCTAssertTrue(field("delivery.context-address").label.contains("1502室"))
        capture("08-修改地址保留手写回复")
    }
    func testMissingInformationAndActionSeparation() {
        launch()
        XCTAssertTrue(app.buttons["delivery.navigate"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["delivery.navigate"].isEnabled)
        XCTAssertFalse(app.buttons["delivery.call"].isEnabled)
        fill("delivery.phone", "6789"); finishEditing()
        XCTAssertFalse(app.buttons["delivery.call"].isEnabled)
        fill("delivery.address", "杭州市西湖区西湖"); finishEditing()
        XCTAssertTrue(app.buttons["delivery.navigate"].isEnabled)
        XCTAssertFalse(app.buttons["delivery.call"].isEnabled)
        XCTAssertTrue(app.buttons["delivery.continue"].isHittable)
        XCTAssertFalse(app.buttons["delivery.navigate"].frame.intersects(app.buttons["delivery.continue"].frame))
        capture("06-不完整号码与操作分离")
        app.buttons["delivery.continue"].tap()
        XCTAssertTrue(app.buttons["电话沟通"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["电话沟通"].isSelected)
        XCTAssertFalse(app.buttons["dialogue.call-customer"].isEnabled)
        capture("07-缺少号码仍可沟通")
    }
}

final class CallStatusAndOrderUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() { continueAfterFailure = false; app = XCUIApplication(bundleIdentifier: "com.ylct.universal") }
    func launch(reset: Bool = true, state: String? = nil, appearance: String = "light") {
        app.launchArguments = ["--review-screen", "dialogue", "--test-custom-phrases", reset ? "success" : "offline", "-ylct.appearance", appearance]
        if reset { app.launchArguments += ["--reset-test-custom-phrases"] }
        if let state { app.launchArguments += ["--test-call-status", state] }
        app.launch()
        XCTAssertTrue(app.buttons["call.status"].waitForExistence(timeout: 12))
    }
    func element(_ id: String) -> XCUIElement { app.descendants(matching: .any).matching(identifier: id).firstMatch }
    func capture(_ name: String) { let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a) }
    func manager() { app.buttons["phrases.manage"].tap(); XCTAssertTrue(app.buttons["phrases.add"].waitForExistence(timeout: 5)) }
    func addPhrase(_ text: String) {
        app.buttons["phrases.add"].tap()
        let field = app.textFields["phrases.editor-text"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(text)
        app.buttons["phrases.dismiss-keyboard"].tap(); app.buttons["phrases.generate"].tap()
        XCTAssertTrue(app.buttons["phrases.sort"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
    }
    func sortRow(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "phrases.order.", text)).firstMatch
    }
    func moveBefore(_ moving: XCUIElement, _ target: XCUIElement) {
        XCTAssertTrue(moving.exists); XCTAssertTrue(target.exists)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let handle = origin.withOffset(CGVector(dx: app.frame.width - 44, dy: moving.frame.midY))
        let destination = origin.withOffset(CGVector(dx: app.frame.width - 44, dy: target.frame.minY + 2))
        handle.press(forDuration: 0.6, thenDragTo: destination)
        let moved = NSPredicate { _, _ in moving.frame.minY < target.frame.minY }
        expectation(for: moved, evaluatedWith: moving)
        waitForExpectations(timeout: 5)
    }
    func testDragSortPersistsAcrossModesAndRelaunch() {
        let first = "我已经到楼下了"
        let second = "麻烦发一张门口照片"
        let builtIn = "我拍张照给您确认"
        launch(); manager(); addPhrase(first); addPhrase(second)
        app.buttons["phrases.done"].tap()
        XCTAssertTrue(app.buttons["phrases.sort-direct"].waitForExistence(timeout: 5))
        app.buttons["phrases.sort-direct"].tap()
        XCTAssertTrue(app.buttons["phrases.sort-done"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["系统预设和自定义，一起排序"].exists)
        let firstRow = sortRow(first), secondRow = sortRow(second), builtInRow = sortRow(builtIn)
        let firstID = String(firstRow.identifier.dropFirst("phrases.order.".count))
        let secondID = String(secondRow.identifier.dropFirst("phrases.order.".count))
        moveBefore(secondRow, firstRow)
        moveBefore(builtInRow, firstRow)
        capture("03-拖动后系统语和自定义语混合排序")
        app.buttons["phrases.sort-done"].tap()
        let a = app.buttons["phrases.quick.\(firstID)"], b = app.buttons["phrases.quick.\(secondID)"]
        let c = app.buttons["phrases.quick.builtin.\(builtIn)"]
        XCTAssertLessThan(b.frame.minY, c.frame.minY); XCTAssertLessThan(c.frame.minY, a.frame.minY)
        XCTAssertFalse(app.buttons["停止播报"].exists, "Dragging cannot start audio")
        capture("04-电话快捷语按新顺序显示")
        app.terminate(); launch(reset: false)
        XCTAssertLessThan(b.frame.minY, c.frame.minY); XCTAssertLessThan(c.frame.minY, a.frame.minY)
        app.segmentedControls.buttons["面对面聊天"].tap()
        XCTAssertTrue(app.staticTexts["常用回复"].exists)
        let faceA = app.buttons["phrases.face.\(firstID)"], faceB = app.buttons["phrases.face.\(secondID)"]
        XCTAssertTrue(faceA.exists); XCTAssertTrue(faceB.exists)
        XCTAssertLessThan(faceB.frame.minX, faceA.frame.minX)
        capture("05-重启后面对面沿用保存顺序")
    }
    func testCompactStatusBarAndHonestStateDetails() {
        for (state, title) in [("waiting", "注入已开启 · 等待通话"), ("ready", "通话注入已开启"), ("off", "通话注入未开启"), ("systemDisabled", "通话注入需系统设置"), ("denied", "通话注入未授权"), ("undetermined", "通话注入待授权"), ("failed", "通话注入开启失败")] {
            launch(state: state)
            let bar = app.buttons["call.status"]
            XCTAssertEqual(bar.label, title)
            XCTAssertLessThanOrEqual(bar.frame.height, 52)
            XCTAssertFalse(app.staticTexts["电话里也能替你说"].exists)
            app.swipeUp(); XCTAssertTrue(bar.isHittable, "Status remains visible while browsing shortcuts")
            bar.tap()
            XCTAssertTrue(app.staticTexts["call.status-detail"].waitForExistence(timeout: 5))
            if state == "ready" { XCTAssertTrue(app.staticTexts["call.status-detail"].label.contains("此状态不代表对方已经听到")) }
            if state == "systemDisabled" || state == "denied" { XCTAssertTrue(app.buttons["打开系统设置"].exists) }
            app.terminate()
        }
        launch(); capture("01-浅色紧凑电话状态条")
        app.terminate(); launch(appearance: "dark"); capture("02-深色紧凑电话状态条")
    }
}

final class CustomPhraseUITests: XCTestCase {
    var app: XCUIApplication!
    let phrase = "我在小区门口，马上到"
    override func setUp() { continueAfterFailure = false; app = XCUIApplication(bundleIdentifier: "com.ylct.universal") }
    func launch(mode: String = "success", reset: Bool = true, screen: String = "account") {
        app.launchArguments = ["--review-screen", screen, "--test-custom-phrases", mode, "-ylct.appearance", "light", "-ylct.voiceGender", "female"]
        if reset { app.launchArguments.append("--reset-test-custom-phrases") }
        app.launch()
    }
    func capture(_ name: String) { let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a) }
    func manager() { XCTAssertTrue(app.buttons["phrases.manage"].waitForExistence(timeout: 12)); app.buttons["phrases.manage"].tap(); XCTAssertTrue(app.buttons["phrases.add"].waitForExistence(timeout: 5)) }
    func generate() {
        app.buttons["phrases.add"].tap()
        let field = app.textFields["phrases.editor-text"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(phrase)
        app.buttons["phrases.dismiss-keyboard"].tap(); capture("01-生成前准备两种声音")
        app.buttons["phrases.generate"].tap()
    }
    func saved() { XCTAssertTrue(app.buttons["试听女声"].waitForExistence(timeout: 10)); XCTAssertTrue(app.buttons["试听男声"].isEnabled) }
    func preview(_ voice: String, name: String) {
        app.buttons["试听\(voice)"].tap()
        let status = app.staticTexts["phrases.playback"]
        XCTAssertTrue(status.label.contains(name))
        let progress = app.descendants(matching: .any).matching(identifier: "playback.preview.pinned").firstMatch
        let done = NSPredicate(format: "value CONTAINS %@", "播报结束")
        expectation(for: done, evaluatedWith: progress)
        waitForExpectations(timeout: 20)
    }
    func testBothVoicesPersistAndPlayOfflineInConversation() {
        launch(); manager(); generate(); saved()
        preview("女声", name: "冰糖"); preview("男声", name: "苏打"); capture("02-男女声均保存并试听")
        app.terminate(); launch(mode: "offline", reset: false); manager(); saved()
        preview("女声", name: "冰糖"); preview("男声", name: "苏打"); capture("03-重启离线仍能播放")
        app.buttons["phrases.done"].tap(); app.buttons["tab.首页"].tap(); app.buttons["home.chat"].tap()
        XCTAssertTrue(app.buttons["conversation.listen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["常用回复"].exists)
        XCTAssertTrue(app.buttons[phrase].waitForExistence(timeout: 5)); app.buttons[phrase].tap()
        XCTAssertTrue(app.staticTexts["播报结束"].firstMatch.waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts[phrase].exists)
        XCTAssertTrue(app.staticTexts["麦克风已暂停"].exists)
        capture("04-面对面直接使用自定义回复")
    }
    func testAddingOnlyShowsSuccessAndDoesNotPlayAudio() {
        launch(); manager(); generate()
        let toast = app.descendants(matching: .any).matching(identifier: "phrases.saved-toast").firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 10))
        XCTAssertTrue(toast.label.contains("添加成功"))
        saved()
        XCTAssertFalse(app.staticTexts["phrases.playback"].exists, "Saving never starts a preview")
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "playback.preview.pinned").firstMatch.exists)
        XCTAssertFalse(app.buttons["停止试听"].exists)
        capture("10-添加完成只显示成功提示")
    }
    func testPartialFailureDoesNotSaveAndCanCancel() {
        launch(mode: "male-failure"); manager(); generate()
        XCTAssertTrue(app.staticTexts["phrases.generation-error"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "phrases.saved-toast").firstMatch.exists)
        XCTAssertTrue(app.buttons["phrases.generate"].isEnabled)
        XCTAssertTrue(app.staticTexts["已生成"].exists)
        capture("05-只成功一种声音不会保存")
        app.buttons["取消"].tap()
        XCTAssertTrue(app.buttons["phrases.add"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["试听女声"].exists)
        XCTAssertFalse(app.buttons["试听男声"].exists)
    }
    func testEditAndDeleteRequireExplicitActions() {
        launch(); manager(); generate(); saved()
        app.buttons["修改文字"].tap()
        let field = app.textFields["phrases.editor-text"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); XCTAssertEqual(field.value as? String, phrase)
        field.tap(); field.typeText("，谢谢。")
        let changed = field.value as? String
        app.buttons["phrases.dismiss-keyboard"].tap(); app.buttons["phrases.generate"].tap(); saved()
        XCTAssertTrue(app.staticTexts[changed!].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "试听女声").count, 1)
        app.buttons["删除"].tap(); XCTAssertTrue(app.alerts["删除这句常用语？"].waitForExistence(timeout: 5))
        app.alerts.buttons["取消"].tap(); XCTAssertTrue(app.buttons["试听女声"].exists)
        app.buttons["删除"].tap(); app.alerts.buttons["删除"].tap()
        XCTAssertFalse(app.buttons["试听女声"].exists); XCTAssertFalse(app.buttons["试听男声"].exists)
    }
}

final class UniversalFlowUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.ylct.universal")
    override func setUp() { continueAfterFailure = false }
    func launch(_ screen: String = "home", reset: Bool = true) {
        app.launchArguments = ["--review-screen", screen, "--test-universal", "--test-custom-phrases", "offline", "--test-external-links"]
        if reset { app.launchArguments += ["--reset-universal","--reset-test-custom-phrases"] }
        app.launch()
    }
    func element(_ key: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: key).firstMatch
    }
    func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    func testSilentExchangeSavedOnlyOnRequest() {
        launch()
        capture("沟通首页")
        app.buttons["universal.text-only"].tap()
        XCTAssertTrue(app.staticTexts["双方打字 · 静音"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["conversation.listen"].exists)
        let draft = element("conversation.draft")
        draft.tap(); draft.typeText("在几号窗口办理")
        app.buttons["conversation.send"].tap()
        XCTAssertTrue(app.staticTexts["在几号窗口办理"].exists)
        XCTAssertFalse(element("playback.face.pinned").exists)
        app.buttons["请对方打字"].tap()
        let partner = element("conversation.partner-draft")
        partner.tap(); partner.typeText("请去二号窗口")
        app.buttons["交给我"].tap()
        XCTAssertTrue(app.staticTexts["请去二号窗口"].waitForExistence(timeout: 6))
        XCTAssertFalse(element("playback.face.pinned").exists)
        capture("双方文字交流")
        app.buttons["对话设置"].tap(); app.buttons["保存本次对话"].tap()
        app.buttons["知道了"].tap()
        app.terminate(); launch("account", reset: false)
        app.buttons["保存的对话"].tap()
        app.buttons.containing(.staticText, identifier: "请去二号窗口").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["在几号窗口办理"].exists)
        XCTAssertTrue(app.staticTexts["请去二号窗口"].exists)
    }
    func testSceneQuoteToDraftAndSeparateHome() {
        launch("scenes")
        app.buttons["scene.kind.shopping"].tap()
        let field = element("scene.questions")
        field.tap(); field.typeText("这个有其他颜色吗")
        app.buttons["scene.dismiss-keyboard"].tap()
        app.buttons["scene.start"].tap()
        app.buttons["dialogue.scene"].tap()
        app.buttons["scene.context-quote"].firstMatch.tap()
        XCTAssertEqual(element("conversation.draft").value as? String, "这个有其他颜色吗")
        XCTAssertFalse(element("playback.face.pinned").exists)
        capture("资料引用到回复")
        app.buttons["关闭"].firstMatch.tap()
        app.buttons["tab.沟通"].tap()
        app.buttons["universal.face"].tap()
        XCTAssertFalse(element("dialogue.scene").exists)
        XCTAssertNotEqual(element("conversation.draft").value as? String, "这个有其他颜色吗")
    }
    func testFavoritesPreferencesAndPhone() {
        launch()
        app.buttons["universal.preference"].tap()
        app.buttons["preference.textOnly"].tap()
        app.buttons["完成"].tap()
        app.buttons["universal.face"].tap()
        XCTAssertTrue(app.staticTexts["双方打字 · 静音"].waitForExistence(timeout: 6))
        app.buttons["关闭"].firstMatch.tap()
        app.buttons["home.more"].tap()
        app.buttons["tab.常用语"].tap()
        let phrase = "请再说一遍，慢一点，谢谢。"
        app.buttons["收藏或取消收藏" + phrase].tap()
        app.buttons["收藏"].tap()
        XCTAssertTrue(app.buttons[phrase].exists)
        XCTAssertFalse(app.buttons["请稍等，我正在打字。"].exists)
        app.buttons["tab.沟通"].tap(); app.buttons["universal.phone"].tap()
        XCTAssertTrue(app.buttons["call.status"].waitForExistence(timeout: 8))
        app.buttons["拨号与联系人"].tap()
        XCTAssertTrue(app.textFields["完整电话号码"].exists)
        XCTAssertFalse(app.buttons["核对并拨打"].isEnabled)
    }
}

extension UniversalFlowUITests {
    func testHomePullAndRelease() {
        launch()
        XCTAssertTrue(app.buttons["home.more"].waitForExistence(timeout: 5))
        let start = app.coordinate(withNormalizedOffset: .init(dx: 0.50, dy: 0.22))
        let end = app.coordinate(withNormalizedOffset: .init(dx: 0.50, dy: 0.80))
        print("YS_PULL_BEGIN")
        start.press(forDuration: 0.12, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 4)
        XCTAssertTrue(app.buttons["home.more"].isHittable)
    }
    func testHomeKeepsScrollAcrossTabs() {
        launch()
        XCTAssertTrue(app.buttons["home.more"].waitForExistence(timeout: 5))
        app.swipeUp()
        let card = app.buttons["universal.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let y = card.frame.midY
        for tab in ["场景", "常用语", "我的"] {
            app.buttons["tab." + tab].tap()
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: 4), app.debugDescription)
            XCTAssertFalse(card.exists, app.debugDescription)
            app.buttons["tab.沟通"].tap()
            XCTAssertTrue(card.isHittable)
            XCTAssertEqual(card.frame.midY, y, accuracy: 2)
            XCTAssertFalse(app.buttons["home.more"].exists)
        }
        app.buttons["home.restore"].tap()
        XCTAssertTrue(app.buttons["home.more"].waitForExistence(timeout: 5))
    }
    func testHomeSceneRoundTrip() {
        launch()
        let primary = app.buttons["universal.face"]
        XCTAssertTrue(primary.isHittable && app.buttons["universal.phone"].isHittable && app.buttons["universal.text-only"].isHittable)
        XCTAssertFalse(app.buttons["tab.我的"].exists)
        capture("2.5-全屏首页")
        let lower = primary.frame.midY
        app.swipeUp()
        XCTAssertTrue(app.buttons["tab.我的"].waitForExistence(timeout: 5))
        XCTAssertLessThan(primary.frame.midY, lower - 120)
        capture("2.5-收起的风景")
        let photo = app.buttons["壁纸设置"].coordinate(withNormalizedOffset: CGVector(dx: -2.6, dy: 1.2))
        photo.press(forDuration: 0.08, thenDragTo: photo.withOffset(CGVector(dx: 0, dy: 420)))
        XCTAssertTrue(app.buttons["home.more"].waitForExistence(timeout: 5))
        app.buttons["home.more"].tap()
        app.buttons["home.restore"].tap()
        XCTAssertTrue(app.buttons["home.more"].waitForExistence(timeout: 5))
        app.buttons["home.more"].tap()
        app.buttons["home.scene.shopping"].tap()
        let bar = app.navigationBars["购物"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        bar.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["universal.face"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["universal.card"].isHittable)
    }
    func testHomeWeather() {
        launch()
        app.buttons["home.weather"].tap()
        XCTAssertTrue(app.navigationBars["出行天气"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["使用当前位置"].exists || app.buttons["在设置中允许定位"].exists)
        capture("出行天气详情")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["universal.face"].isHittable)
        XCTAssertTrue(app.buttons["universal.phone"].isHittable)
    }
    func testSceneSaveAndConfirmedExternalActions() {
        launch("scenes")
        app.buttons["scene.kind.shopping"].tap()
        func input(_ key: String, _ text: String) {
            let field = element(key)
            for _ in 0..<5 where !field.isHittable { app.swipeUp() }
            field.tap(); field.typeText(text); app.buttons["scene.dismiss-keyboard"].tap()
        }
        input("scene.title", "周五取件")
        input("scene.address", "湖滨路八号")
        input("scene.phone", "13800001234")
        app.buttons["scene.call"].tap()
        XCTAssertTrue(app.alerts["核对联系电话"].exists)
        app.buttons["取消"].tap()
        app.buttons["scene.navigate"].tap()
        app.buttons["步行导航"].tap()
        XCTAssertTrue(app.alerts.containing(.staticText, identifier: "操作提示").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "maps.apple.com")).firstMatch.exists)
        app.buttons["知道了"].tap()
        let save = app.buttons["scene.save"]
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(element("scene.feedback").waitForExistence(timeout: 5))
        app.terminate(); launch("scenes", reset: false)
        let saved = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'scene.saved.'")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 6))
        app.buttons["scene.saved-route"].tap()
        XCTAssertTrue(app.staticTexts["确认目的地：湖滨路八号"].waitForExistence(timeout: 4))
        capture("场景路线确认")
        app.buttons["复制地址"].tap()
        saved.tap()
        XCTAssertEqual(element("scene.title").value as? String, "周五取件")
        for (key, value) in [("scene.address", "湖滨路八号"), ("scene.phone", "13800001234")] {
            let field = element(key)
            for _ in 0..<5 where !field.isHittable { app.swipeUp() }
            XCTAssertEqual(field.value as? String, value)
        }
    }
    func testRiderOptInAndReplayGuide() {
        launch("account")
        let toggle = app.switches["account.rider"]
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.switches.firstMatch.exists ? toggle.switches.firstMatch.tap() : toggle.tap()
        app.buttons["tab.场景"].tap()
        for _ in 0..<5 where !app.buttons["送餐准备"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["送餐准备"].isHittable)
        app.buttons["tab.我的"].tap()
        app.buttons["account.onboarding"].tap()
        XCTAssertTrue(element("onboarding.skip").waitForExistence(timeout: 5))
        element("onboarding.skip").tap()
        XCTAssertTrue(app.buttons["account.onboarding"].exists)
    }
}

extension UniversalFlowUITests {
    func testOpeningContactWallpaperAndDefault() throws {
        launch()
        XCTAssertTrue(app.buttons["universal.preference"].label.contains("打字播报"))
        app.buttons["壁纸设置"].tap()
        app.buttons["换一幅风景"].tap()
        capture("新首页风景")
        app.buttons["universal.phone"].tap()
        app.buttons["拨号与联系人"].tap()
        app.buttons["从通讯录选择号码"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("Appleseed")
        let cells = app.cells.matching(NSPredicate(format: "label == %@", "John Appleseed"))
        XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 6))
        let filteredContact = try XCTUnwrap(cells.allElementsBoundByIndex.last(where: { $0.isHittable }))
        filteredContact.tap()
        let tel = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "1212")).firstMatch
        XCTAssertTrue(tel.waitForExistence(timeout: 5))
        tel.tap()
        let dial = app.buttons["核对并拨打"]
        let usable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true AND hittable == true"), object: dial)
        XCTAssertEqual(XCTWaiter.wait(for: [usable], timeout: 8), .completed)
        app.buttons["设置开场白与常用联系人"].tap()
        let toggle = app.switches["opening.auto"]; (toggle.switches.firstMatch.exists ? toggle.switches.firstMatch : toggle).tap()
        app.buttons["添加常用联系人"].tap()
        app.textFields["称呼"].tap(); app.textFields["称呼"].typeText("小林")
        app.textFields["完整电话号码"].tap(); app.textFields["完整电话号码"].typeText("13800001234")
        app.buttons.containing(.staticText, identifier: "专属开场白").firstMatch.tap()
        app.buttons["好的，谢谢！"].tap()
        app.buttons["保存"].tap()
        app.terminate()
        launch(reset: false)
        app.buttons["universal.phone"].tap()
        app.buttons["拨号与联系人"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "小林")).firstMatch.tap()
        XCTAssertEqual(app.textFields["完整电话号码"].value as? String, "13800001234")
        app.buttons["核对并拨打"].tap()
        XCTAssertTrue(app.alerts.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "接通后的开场白：好的，谢谢！")).firstMatch.exists)
        capture("确认拨号与专属开场")
        app.alerts.buttons["取消"].tap()
    }
}

extension UniversalFlowUITests {
    func testNewDefaultOpeningSavedOffline() {
        app.launchArguments = ["--review-screen","account","--test-universal","--reset-universal","--test-custom-phrases","success","--reset-test-custom-phrases","--test-external-links"]
        app.launch()
        app.buttons["通话开场与常用联系人"].tap()
        app.buttons.containing(.staticText, identifier: "通用开场白").firstMatch.tap()
        app.buttons["写一句新开场白"].tap()
        let field = element("phrases.editor-text")
        field.tap(); field.typeText("您好我现在用文字接电话")
        app.buttons["phrases.dismiss-keyboard"].tap()
        app.buttons["phrases.generate"].tap()
        XCTAssertTrue(app.staticTexts["添加成功，已选为开场白"].waitForExistence(timeout: 14))
        app.terminate(); launch(reset: false)
        app.buttons["universal.phone"].tap(); app.buttons["拨号与联系人"].tap()
        XCTAssertTrue(app.staticTexts["您好我现在用文字接电话"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("opening.progress").exists)
    }
}
