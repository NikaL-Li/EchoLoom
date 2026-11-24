import XCTest
@testable import FeatureScenes

private final class RecordingSessionStore: YZSessionStoring {
    var saved: [YZSceneSession] = []
    var shouldFail = false

    func save(_ session: YZSceneSession) throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "模拟失败"])
        }
        saved.append(session)
    }
}

final class SceneSwitchTests: XCTestCase {
    private var turn: YZConversationTurn {
        YZConversationTurn(speaker: .patient, text: "你好")
    }

    func testInitialStateUsesDefaultSub() {
        XCTAssertEqual(YZSceneSwitching(scene: .medical).sub, "问诊")
        XCTAssertEqual(YZSceneSwitching(scene: .dining).sub, "点单")
        XCTAssertEqual(YZSceneSwitching(scene: .emergency).sub, "求助")
    }

    func testSwitchSceneSavesSessionWhenSpoken() {
        var model = YZSceneSwitching(scene: .medical)
        let store = RecordingSessionStore()

        let outcome = model.switchScene(to: .dining, turns: [turn], store: store)

        XCTAssertTrue(outcome.savedSession)
        XCTAssertEqual(store.saved.count, 1)
        XCTAssertEqual(store.saved.first?.scene, .medical)
        XCTAssertEqual(store.saved.first?.sub, "问诊")
        XCTAssertEqual(store.saved.first?.turns.count, 1)
        XCTAssertEqual(model.scene, .dining)
        XCTAssertEqual(model.sub, "点单")
        XCTAssertEqual(model.dividerText, "— 点餐 · 点单 新会话 —")
        XCTAssertNil(outcome.saveError)
    }

    func testSwitchSceneWithoutSpokenTurnsDoesNotSave() {
        var model = YZSceneSwitching(scene: .medical)
        let store = RecordingSessionStore()

        let outcome = model.switchScene(to: .transit, turns: [], store: store)

        XCTAssertFalse(outcome.savedSession)
        XCTAssertTrue(store.saved.isEmpty)
        XCTAssertEqual(model.scene, .transit)
        XCTAssertEqual(model.sub, "打车")
        XCTAssertNotNil(model.dividerText)
    }

    func testSwitchSceneKeepsWorkingWhenSessionSaveFails() {
        var model = YZSceneSwitching(scene: .medical)
        let store = RecordingSessionStore()
        store.shouldFail = true

        let outcome = model.switchScene(to: .errands, turns: [turn], store: store)

        XCTAssertFalse(outcome.savedSession)
        XCTAssertNotNil(outcome.saveError)
        XCTAssertEqual(model.scene, .errands)
        XCTAssertEqual(model.sub, "银行")
        XCTAssertNotNil(model.dividerText)
    }

    func testSwitchSubKeepsSceneAndClearsDivider() {
        var model = YZSceneSwitching(scene: .dining)
        let store = RecordingSessionStore()
        _ = model.switchScene(to: .transit, turns: [turn], store: store)
        XCTAssertNotNil(model.dividerText)

        let changed = model.switchSub(to: "问路")

        XCTAssertTrue(changed)
        XCTAssertEqual(model.scene, .transit)
        XCTAssertEqual(model.sub, "问路")
        XCTAssertNil(model.dividerText)
        XCTAssertEqual(model.phrases().count, 6)
    }

    func testSwitchSubRejectsUnknownSub() {
        var model = YZSceneSwitching(scene: .dining)
        XCTAssertTrue(model.switchSub(to: "口味"))

        XCTAssertFalse(model.switchSub(to: "不存在"))
        XCTAssertEqual(model.sub, "口味")
        XCTAssertTrue(SceneCatalog.subs(for: .dining).contains(model.sub))
    }

    func testSwitchSceneRefreshesPhrasesAndTerms() {
        var model = YZSceneSwitching(scene: .medical)
        XCTAssertEqual(model.phrases().count, 6)
        XCTAssertEqual(model.terms().count, 70)

        _ = model.switchScene(to: .emergency, turns: [], store: RecordingSessionStore())

        XCTAssertEqual(model.phrases().count, 6)
        XCTAssertEqual(model.terms().count, 10)
        XCTAssertEqual(model.termHint(for: "我听不见")?.id, "e10")
    }
}