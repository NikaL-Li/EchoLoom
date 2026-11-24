import XCTest
@testable import FeatureScenes

final class SceneCatalogTests: XCTestCase {
    func testEverySceneHasSubs() {
        for scene in SceneKind.allCases {
            let subs = SceneCatalog.subs(for: scene)
            XCTAssertFalse(subs.isEmpty, "\(scene.rawValue) 没有环节")
        }
    }

    func testEveryDefaultSubIsValid() {
        XCTAssertEqual(SceneCatalog.defaultSub(for: .medical), "问诊")

        for scene in SceneKind.allCases {
            let defaultSub = SceneCatalog.defaultSub(for: scene)
            XCTAssertFalse(defaultSub.isEmpty, "\(scene.rawValue) 默认环节为空")
            XCTAssertTrue(
                SceneCatalog.subs(for: scene).contains(defaultSub),
                "\(scene.rawValue) 默认环节不在环节表里"
            )
        }

        for scene in SceneKind.allCases where scene != .medical {
            XCTAssertEqual(
                SceneCatalog.defaultSub(for: scene),
                SceneCatalog.subs(for: scene).first ?? ""
            )
        }
    }

    func testSubCountsMatchHTML() {
        XCTAssertEqual(SceneCatalog.subs(for: .medical), ["挂号", "问诊", "检查", "取药", "缴费"])
        XCTAssertEqual(SceneCatalog.subs(for: .dining), ["点单", "口味", "打包", "结账"])
        XCTAssertEqual(SceneCatalog.subs(for: .transit), ["打车", "公交地铁", "问路", "下车"])
        XCTAssertEqual(SceneCatalog.subs(for: .errands), ["银行", "政务", "快递", "校园"])
        XCTAssertEqual(SceneCatalog.subs(for: .emergency), ["求助", "报警", "身体不适"])
    }

    func testEverySubHasSixPhrases() {
        for scene in SceneKind.allCases {
            for sub in SceneCatalog.subs(for: scene) {
                let phrases = SceneCatalog.phrases(for: scene, sub: sub)
                XCTAssertEqual(phrases.count, 6, "\(scene.rawValue)/\(sub) 不是 6 句")
            }
        }
    }

    func testPhrasesAreNotBlankAndUniqueWithinScene() {
        for scene in SceneKind.allCases {
            var seen = Set<String>()
            for sub in SceneCatalog.subs(for: scene) {
                for phrase in SceneCatalog.phrases(for: scene, sub: sub) {
                    XCTAssertFalse(
                        phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        "\(scene.rawValue)/\(sub) 有空句子"
                    )
                    XCTAssertTrue(
                        seen.insert(phrase).inserted,
                        "\(scene.rawValue) 句子重复：\(phrase)"
                    )
                }
            }
        }
    }

    func testPhraseKeysMatchSubs() {
        for scene in SceneKind.allCases {
            let pack = SceneCatalog.pack(for: scene)
            XCTAssertEqual(Set(pack.phrases.keys), Set(pack.subs))
        }
    }

    func testUnknownSubFallsBackToFirstSub() {
        XCTAssertEqual(
            SceneCatalog.phrases(for: .dining, sub: "不存在"),
            SceneCatalog.phrases(for: .dining, sub: "点单")
        )
    }

    func testNavStyles() {
        XCTAssertEqual(SceneCatalog.pack(for: .medical).navStyle, .step)

        for scene in [SceneKind.dining, .transit, .errands, .emergency] {
            XCTAssertEqual(SceneCatalog.pack(for: scene).navStyle, .tab)
        }
    }

    func testTermCountsMatchHTML() {
        XCTAssertEqual(SceneCatalog.terms(for: .medical).count, 70)

        for scene in [SceneKind.dining, .transit, .errands, .emergency] {
            XCTAssertEqual(SceneCatalog.terms(for: scene).count, 10)
        }
    }

    func testTermIDsAreUnique() {
        let ids = SceneCatalog.allTerms.map(\.id)
        XCTAssertEqual(ids.count, 110)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testTermsAreNotEmpty() {
        for scene in SceneKind.allCases {
            for term in SceneCatalog.terms(for: scene) {
                XCTAssertFalse(term.id.isEmpty)
                XCTAssertFalse(term.standard.isEmpty)
                XCTAssertFalse(term.colloquial.isEmpty)
                XCTAssertFalse(term.ask.isEmpty)
            }
        }
    }
}