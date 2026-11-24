import XCTest
@testable import YiZhen

final class YZModelsTests: XCTestCase {
    func testSceneOrderAndEmergencyFlag() {
        XCTAssertEqual(YZMockData.scenes.map(\.name), ["就医", "点餐", "出行", "办事", "紧急"])
        XCTAssertEqual(YZMockData.scenes.map(\.id), ["medical", "meal", "travel", "service", "emergency"])
        XCTAssertEqual(YZMockData.scenes.filter(\.isEmergency).map(\.id), ["emergency"])
        XCTAssertEqual(YZMockData.scenes.filter(\.isSelected).map(\.id), ["medical"])
    }

    func testPhasesPerSceneCounts() {
        XCTAssertEqual(YZMockData.phases(for: "medical").count, 5)
        XCTAssertEqual(YZMockData.phases(for: "meal").count, 4)
        XCTAssertEqual(YZMockData.phases(for: "travel").count, 4)
        XCTAssertEqual(YZMockData.phases(for: "service").count, 4)
        XCTAssertEqual(YZMockData.phases(for: "emergency").count, 3)
    }

    func testMedicalPhaseNamesAndDefault() {
        XCTAssertEqual(
            YZMockData.phases(for: "medical").map(\.name),
            ["挂号", "问诊", "检查", "取药", "缴费"]
        )
        XCTAssertEqual(YZMockData.defaultPhaseID(for: "medical") ?? "", "medical.question")
        XCTAssertEqual(YZMockData.defaultPhaseID(for: "meal") ?? "", "meal.order")
        XCTAssertEqual(YZMockData.navStyle(of: "medical"), .step)
        XCTAssertEqual(YZMockData.navStyle(of: "meal"), .tab)
    }

    func testEveryScenePhaseHasSixPhrases() {
        for pack in YZMockData.scenePacks {
            for phase in pack.phases {
                XCTAssertEqual(
                    YZMockData.phrases(sceneID: pack.scene.id, phaseID: phase.id).count,
                    6,
                    "\(pack.scene.id) \(phase.id) 句数不足"
                )
            }
        }
    }

    func testTotalPhraseCountIsOneHundredTwenty() {
        let total = YZMockData.scenePacks.reduce(0) { partial, pack in
            partial + pack.phases.reduce(0) { inner, phase in
                inner + YZMockData.phrases(sceneID: pack.scene.id, phaseID: phase.id).count
            }
        }
        XCTAssertEqual(total, 120)
    }

    func testThreeMessageBaselineIsSortedAndUsesNewStatuses() {
        let session = YZMockData.session(baseline: .threeMessages)
        XCTAssertEqual(session.messages.count, 3)
        XCTAssertEqual(session.messages.map(\.id), ["other.1", "mine.1", "mine.2"])
        XCTAssertEqual(session.messages[1].statusText, "文字直达")
        XCTAssertEqual(session.messages[2].statusText, "文字直达")
        XCTAssertEqual(session.messages[0].statusText, "已识别")
        XCTAssertEqual(session.messages[1].statusKind, .plain)
    }

    func testEmptyBaselineHasNoMessages() {
        XCTAssertTrue(YZMockData.session(baseline: .empty).messages.isEmpty)
    }

    func testEmergencyTextsSplitPeriods() {
        XCTAssertEqual(YZMockData.emergencyBannerText, "我听不见，请帮我打 120")
        XCTAssertEqual(YZMockData.emergencyCardText, "我听不见，请帮我打 120。")
    }

    func testCardLabelByScene() {
        let date = YZMockData.threeMessages[0].createdAt
        XCTAssertEqual(YZFormatting.cardLabel(sceneID: "medical", date: date), "医生 · 09:41")
        XCTAssertEqual(YZFormatting.cardLabel(sceneID: "meal", date: date), "对方 · 09:41")
    }

    func testCardAccessibilityLabelContainsSpeakerAndLabel() {
        let message = YZMockData.threeMessages[0]
        let label = YZFormatting.cardAccessibilityLabel(message, sceneID: "medical")
        XCTAssertTrue(label.contains("对方说"))
        XCTAssertTrue(label.contains("请问您哪里不舒服"))
        XCTAssertTrue(label.contains("医生 · 09:41"))
        XCTAssertFalse(label.contains("已识别"))
    }

    func testBlankTextIsFiltered() {
        let message = YZMessage(id: "blank", direction: .mine, text: "   ", statusText: "文字直达", createdAt: Date())
        XCTAssertTrue(YZMessageValidator.normalize([message]).isEmpty)
    }

    func testTextLongerThanFiveHundredIsTruncated() {
        let text = String(repeating: "字", count: 501)
        XCTAssertEqual(YZMessageValidator.normalizedText(text)?.count ?? -1, 500)
    }

    func testInvalidDirectionFallsBackToMine() {
        XCTAssertEqual(YZMessageValidator.normalizedDirection("unknown"), .mine)
        XCTAssertEqual(YZMessageValidator.normalizedDirection(nil), .mine)
        XCTAssertEqual(YZMessageValidator.normalizedDirection("other"), .other)
    }

    func testStatusLongerThanTwentyIsTruncated() {
        let status = String(repeating: "状", count: 25)
        XCTAssertEqual(YZMessageValidator.normalizedStatus(status).count, 20)
    }

    func testTimeFormatIsTwentyFourHourHHmm() {
        let message = YZMockData.threeMessages[0]
        XCTAssertEqual(YZFormatting.time(message.createdAt), "09:41")
        XCTAssertEqual(YZFormatting.statusLine(status: "文字直达", date: message.createdAt), "文字直达 · 09:41")
    }

    func testSceneAndPhaseInvariants() {
        XCTAssertTrue(YZSceneValidator.hasSingleSelection(YZMockData.scenes))
        XCTAssertTrue(YZPhaseValidator.hasAtMostOneCurrent(YZMockData.phases(for: "medical")))
        XCTAssertEqual(YZMockData.phases(for: "medical").first(where: { $0.isCurrent })?.name ?? "", "问诊")
    }

    func testPhraseBaselines() {
        XCTAssertEqual(YZMockData.session(baseline: .threeMessages, phraseBaseline: .six).phrases.count, 6)
        XCTAssertTrue(YZMockData.session(baseline: .threeMessages, phraseBaseline: .empty).phrases.isEmpty)
    }

    func testStatusKindMappingIsUnique() {
        let date = Date()
        let cases: [(String, YZStatusKind)] = [
            ("文字直达", .plain),
            ("已播报", .ok),
            ("播报失败", .fail),
            ("已识别", .plain),
            ("未知状态", .plain)
        ]
        for (text, expected) in cases {
            let message = YZMessage(id: text, direction: .mine, text: "测试", statusText: text, createdAt: date)
            XCTAssertEqual(message.statusKind, expected)
        }
    }

    func testCardLabelUsesCreatedAtAndScene() {
        XCTAssertEqual(YZFormatting.cardLabel(sceneID: "medical", date: date(hour: 14, minute: 32)), "医生 · 14:32")
        XCTAssertEqual(YZFormatting.cardLabel(sceneID: "meal", date: date(hour: 14, minute: 32)), "对方 · 14:32")
    }

    func testCardAccessibilityLabelCombinesStatusOrSpeaker() {
        let createdAt = date(hour: 14, minute: 32)
        let mine = YZMessage(id: "mine", direction: .mine, text: "我听力不好。", statusText: "文字直达", createdAt: createdAt)
        let other = YZMessage(id: "other", direction: .other, text: "请说慢一点。", statusText: "已识别", createdAt: createdAt)

        let mineLabel = YZFormatting.cardAccessibilityLabel(mine, sceneID: "medical")
        XCTAssertTrue(mineLabel.contains("我说"))
        XCTAssertTrue(mineLabel.contains("文字直达"))
        XCTAssertTrue(mineLabel.contains("14:32"))

        let otherLabel = YZFormatting.cardAccessibilityLabel(other, sceneID: "medical")
        XCTAssertTrue(otherLabel.contains("对方说"))
        XCTAssertTrue(otherLabel.contains("医生 · 14:32"))
        XCTAssertFalse(otherLabel.contains("已识别"))
    }

    private func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    func testBaselineResolvesFromEnvironmentAndArguments() {
        XCTAssertEqual(YZBaseline.resolve(fromEnvironment: [:], arguments: []), .threeMessages)
        XCTAssertEqual(YZBaseline.resolve(fromEnvironment: ["YZ_BASELINE": "empty"], arguments: []), .empty)
        XCTAssertEqual(YZBaseline.resolve(fromEnvironment: [:], arguments: ["-YZ_BASELINE", "empty"]), .empty)
        XCTAssertEqual(YZBaseline.resolve(fromEnvironment: ["YZ_BASELINE": "unknown"], arguments: []), .threeMessages)
    }
}