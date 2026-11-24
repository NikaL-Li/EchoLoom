import XCTest
@testable import FeatureScenes

final class TermMatcherTests: XCTestCase {
    func testMatchesStandardTerm() {
        let terms = SceneCatalog.terms(for: .medical)
        XCTAssertEqual(TermMatcher.match("医生说我持续性疼痛", in: terms)?.id, "t01")
    }

    func testMatchesColloquialTerm() {
        let terms = SceneCatalog.terms(for: .medical)
        XCTAssertEqual(TermMatcher.match("我一直疼", in: terms)?.id, "t01")
        XCTAssertEqual(TermMatcher.match("我发烧了", in: terms)?.id, "t07")
    }

    func testLongestMatchWins() {
        let terms = [
            Term(id: "short", category: "测试", standard: "疼痛", colloquial: "疼", ask: "短"),
            Term(id: "long", category: "测试", standard: "持续性疼痛", colloquial: "一直疼", ask: "长")
        ]

        XCTAssertEqual(TermMatcher.match("我一直疼，而且持续性疼痛", in: terms)?.id, "long")
    }

    func testSingleCharacterKeysAreIgnored() {
        let terms = [
            Term(id: "single", category: "测试", standard: "痒", colloquial: "", ask: "单字")
        ]

        XCTAssertNil(TermMatcher.match("有点痒", in: terms))
    }

    func testNoMatchReturnsNil() {
        let terms = SceneCatalog.terms(for: .medical)
        XCTAssertNil(TermMatcher.match("今天天气不错", in: terms))
        XCTAssertNil(TermMatcher.match("", in: terms))
        XCTAssertNil(TermMatcher.match("   \n", in: terms))
    }

    func testMatchingDoesNotModifyText() {
        let terms = SceneCatalog.terms(for: .medical)
        let original = "我发烧了"
        XCTAssertNotNil(TermMatcher.match(original, in: terms))
        XCTAssertEqual(original, "我发烧了")
    }

    func testSceneTermsAreUsed() {
        let dining = SceneCatalog.terms(for: .dining)
        XCTAssertEqual(TermMatcher.match("现在点菜吗", in: dining)?.id, "c01")
        XCTAssertNil(TermMatcher.match("我发烧了", in: dining))
    }
}