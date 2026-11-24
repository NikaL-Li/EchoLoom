import XCTest
@testable import YiZhen

@MainActor
final class YZAppStateTests: XCTestCase {
    private func makeState(
        baseline: YZBaseline = .threeMessages,
        phraseBaseline: YZPhraseBaseline = .six
    ) -> YZAppState {
        YZAppState(
            session: YZMockData.session(baseline: baseline, phraseBaseline: phraseBaseline),
            phraseBaseline: phraseBaseline
        )
    }

    func testDefaultSelectionIsMedicalQuestion() {
        let state = makeState()
        XCTAssertEqual(state.selectedSceneID, "medical")
        XCTAssertEqual(state.selectedPhaseID ?? "", "medical.question")
        XCTAssertEqual(state.currentPhaseID ?? "", "medical.question")
        XCTAssertEqual(state.selectedView, .dialog)
        XCTAssertEqual(state.phrases.count, 6)
        XCTAssertEqual(state.selectedScene?.name ?? "", "就医")
    }

    func testSceneSelectionResetsSecondaryAndPhrases() {
        let state = makeState()
        state.selectScene("meal")
        XCTAssertEqual(state.selectedSceneID, "meal")
        XCTAssertEqual(state.phases.count, 4)
        XCTAssertEqual(state.selectedPhaseID ?? "", "meal.order")
        XCTAssertEqual(state.currentPhaseID ?? "", "meal.order")
        XCTAssertEqual(state.phrases.count, 6)

        state.selectScene("emergency")
        XCTAssertEqual(state.selectedPhaseID ?? "", "emergency.help")
        XCTAssertEqual(state.phases.count, 3)
        XCTAssertTrue(state.emergencyBanner.visible)
    }

    func testSelectingSameSceneIsIdempotent() {
        let state = makeState()
        state.selectScene("emergency")
        state.selectScene("emergency")
        XCTAssertEqual(state.selectedSceneID, "emergency")
        XCTAssertEqual(state.selectedPhaseID ?? "", "emergency.help")
    }

    func testInvalidSceneIsIgnored() {
        let state = makeState()
        state.selectScene("missing")
        XCTAssertEqual(state.selectedSceneID, "medical")
    }

    func testSelectPhaseRefreshesPhrases() {
        let state = makeState()
        state.selectPhase("medical.payment")
        XCTAssertEqual(state.selectedPhaseID ?? "", "medical.payment")
        XCTAssertEqual(state.currentPhaseID ?? "", "medical.payment")
        XCTAssertEqual(state.phrases.count, 6)
        XCTAssertTrue(state.phrases.allSatisfy { $0.id.hasPrefix("medical.payment.") })
    }

    func testSelectPhaseIdempotentAndInvalidIgnored() {
        let state = makeState()
        state.selectPhase("medical.question")
        XCTAssertEqual(state.selectedPhaseID ?? "", "medical.question")
        state.selectPhase("meal.pack")
        XCTAssertEqual(state.selectedPhaseID ?? "", "medical.question")
    }

    func testPhraseBaselineEmptyStaysEmptyAcrossSceneChange() {
        let state = makeState(phraseBaseline: .empty)
        XCTAssertTrue(state.phrases.isEmpty)
        state.selectScene("travel")
        XCTAssertTrue(state.phrases.isEmpty)
        state.selectPhase("travel.ask")
        XCTAssertTrue(state.phrases.isEmpty)
    }

    func testEmergencyBannerDerivation() {
        let state = makeState()
        XCTAssertFalse(state.emergencyBanner.visible)
        XCTAssertEqual(state.emergencyBanner.text, "我听不见，请帮我打 120")
        state.selectScene("emergency")
        XCTAssertTrue(state.emergencyBanner.visible)
        XCTAssertFalse(state.emergencyBanner.interactive)
        state.selectScene("service")
        XCTAssertFalse(state.emergencyBanner.visible)
    }

    func testSelectedViewToggles() {
        let state = makeState()
        state.selectView(.phrases)
        XCTAssertEqual(state.selectedView, .phrases)
        state.selectView(.phrases)
        XCTAssertEqual(state.selectedView, .phrases)
        state.selectView(.dialog)
        XCTAssertEqual(state.selectedView, .dialog)
    }

    func testReplaceBaselineKeepsOrdering() {
        let state = makeState()
        state.replaceBaseline(messages: Array(YZMockData.threeMessages.reversed()))
        XCTAssertEqual(state.messages.map(\.id), ["other.1", "mine.1", "mine.2"])
        state.replaceBaseline(messages: [])
        XCTAssertTrue(state.messages.isEmpty)
    }

    func testNavStyleAndDefaultPhaseHelpers() {
        let state = makeState()
        XCTAssertEqual(state.navStyle(of: "medical"), .step)
        XCTAssertEqual(state.navStyle(of: "meal"), .tab)
        XCTAssertEqual(state.defaultPhaseID(for: "medical") ?? "", "medical.question")
        XCTAssertEqual(state.phases(for: "service").count, 4)
    }

    func testSendMineTextRejectsEmptyAndWhitespace() {
        let state = makeState()
        let before = state.messages.count
        XCTAssertNil(state.sendMineText(""))
        XCTAssertNil(state.sendMineText("   \n "))
        XCTAssertEqual(state.messages.count, before)
    }

    func testSendMineTextAppendsPlainMineMessage() {
        let state = makeState()
        let beforeCount = state.messages.count
        let id = state.sendMineText("  请帮我写下来。  ")

        XCTAssertEqual(id ?? "", "mine.c1")
        XCTAssertEqual(state.messages.count, beforeCount + 1)
        XCTAssertEqual(state.messages.last?.id ?? "", "mine.c1")
        XCTAssertEqual(state.messages.last?.direction ?? .other, .mine)
        XCTAssertEqual(state.messages.last?.text ?? "", "请帮我写下来。")
        XCTAssertEqual(state.messages.last?.statusText ?? "", "文字直达")
        XCTAssertEqual(state.messages.last?.statusKind ?? .fail, .plain)
        XCTAssertGreaterThanOrEqual(
            state.messages.last?.createdAt ?? .distantPast,
            state.messages[beforeCount - 1].createdAt
        )
    }

    func testSendMineTextHonorsFiveHundredLimit() {
        let state = makeState()
        XCTAssertNotNil(state.sendMineText(String(repeating: "字", count: 500)))
        XCTAssertNil(state.sendMineText(String(repeating: "字", count: 501)))
    }
}