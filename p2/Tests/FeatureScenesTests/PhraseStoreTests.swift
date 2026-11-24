import XCTest
@testable import FeatureScenes

private final class MemoryKeyValueStore: YZKeyValueStore {
    var storage: [String: Data] = [:]
    var failWrite = false

    func read(_ key: String) -> Data? {
        storage[key]
    }

    func write(_ data: Data, for key: String) throws {
        if failWrite {
            throw YZPhraseError.saveFailed("模拟失败")
        }
        storage[key] = data
    }
}

final class PhraseStoreTests: XCTestCase {
    private func makeStore() -> (YZUserDefaultsPhraseStore, MemoryKeyValueStore) {
        let memory = MemoryKeyValueStore()
        let store = YZUserDefaultsPhraseStore(store: memory, key: "test.phrases")
        return (store, memory)
    }

    func testGroupKeyUsesSceneSubFormat() {
        XCTAssertEqual(
            YZUserDefaultsPhraseStore.groupKey(scene: .medical, sub: "问诊"),
            "就医|问诊"
        )
    }

    func testAddKeepsInsertionOrder() throws {
        let (store, _) = makeStore()
        try store.addPhrase("第一句", scene: .medical, sub: "问诊")
        try store.addPhrase("第二句", scene: .medical, sub: "问诊")
        try store.addPhrase("第三句", scene: .medical, sub: "问诊")

        XCTAssertEqual(
            try store.customPhrases(scene: .medical, sub: "问诊"),
            ["第一句", "第二句", "第三句"]
        )
    }

    func testGroupsAreIsolated() throws {
        let (store, _) = makeStore()
        try store.addPhrase("问诊句", scene: .medical, sub: "问诊")
        try store.addPhrase("点单句", scene: .dining, sub: "点单")

        XCTAssertEqual(try store.customPhrases(scene: .medical, sub: "问诊"), ["问诊句"])
        XCTAssertEqual(try store.customPhrases(scene: .dining, sub: "点单"), ["点单句"])
        XCTAssertEqual(try store.customPhrases(scene: .medical, sub: "挂号"), [])
    }

    func testBlankIsRejected() {
        let (store, _) = makeStore()

        for blank in ["", "   ", "\n\t"] {
            XCTAssertThrowsError(try store.addPhrase(blank, scene: .medical, sub: "问诊")) { error in
                XCTAssertEqual(error as? YZPhraseError, YZPhraseError.emptyText)
            }
        }
    }

    func testTextIsTrimmedBeforeSaving() throws {
        let (store, _) = makeStore()
        try store.addPhrase("  请说慢一点。  ", scene: .medical, sub: "问诊")
        XCTAssertEqual(try store.customPhrases(scene: .medical, sub: "问诊"), ["请说慢一点。"])
    }

    func testSixtyCharactersPassAndSixtyOneIsRejected() throws {
        let (store, _) = makeStore()
        let sixty = String(repeating: "字", count: 60)
        let sixtyOne = String(repeating: "字", count: 61)

        XCTAssertNoThrow(try store.addPhrase(sixty, scene: .medical, sub: "问诊"))

        XCTAssertThrowsError(try store.addPhrase(sixtyOne, scene: .medical, sub: "问诊")) { error in
            XCTAssertEqual(error as? YZPhraseError, YZPhraseError.tooLong(limit: 60))
        }
    }

    func testDuplicateIsRejected() throws {
        let (store, _) = makeStore()
        try store.addPhrase("请写下来给我看。", scene: .medical, sub: "问诊")

        XCTAssertThrowsError(
            try store.addPhrase("请写下来给我看。", scene: .medical, sub: "问诊")
        ) { error in
            XCTAssertEqual(error as? YZPhraseError, YZPhraseError.duplicate)
        }
    }

    func testUpdateReplacesInPlace() throws {
        let (store, _) = makeStore()
        try store.addPhrase("旧句子", scene: .medical, sub: "问诊")
        try store.addPhrase("第二句", scene: .medical, sub: "问诊")
        try store.updatePhrase("旧句子", to: "新句子", scene: .medical, sub: "问诊")

        XCTAssertEqual(
            try store.customPhrases(scene: .medical, sub: "问诊"),
            ["新句子", "第二句"]
        )
    }

    func testUpdateToDuplicateIsRejected() throws {
        let (store, _) = makeStore()
        try store.addPhrase("甲", scene: .medical, sub: "问诊")
        try store.addPhrase("乙", scene: .medical, sub: "问诊")

        XCTAssertThrowsError(
            try store.updatePhrase("甲", to: "乙", scene: .medical, sub: "问诊")
        ) { error in
            XCTAssertEqual(error as? YZPhraseError, YZPhraseError.duplicate)
        }
    }

    func testDeleteReturnsToEmptyState() throws {
        let (store, _) = makeStore()
        try store.addPhrase("唯一一句", scene: .dining, sub: "点单")
        try store.deletePhrase("唯一一句", scene: .dining, sub: "点单")

        XCTAssertEqual(try store.customPhrases(scene: .dining, sub: "点单"), [])
        XCTAssertEqual(try store.allCustomPhrases(), [:])
    }

    func testDataSurvivesStoreRecreation() throws {
        let memory = MemoryKeyValueStore()
        let first = YZUserDefaultsPhraseStore(store: memory, key: "test.phrases")
        try first.addPhrase("重启后还在", scene: .emergency, sub: "求助")

        let second = YZUserDefaultsPhraseStore(store: memory, key: "test.phrases")
        XCTAssertEqual(
            try second.customPhrases(scene: .emergency, sub: "求助"),
            ["重启后还在"]
        )
    }

    func testSaveFailureIsReported() {
        let memory = MemoryKeyValueStore()
        memory.failWrite = true
        let store = YZUserDefaultsPhraseStore(store: memory, key: "test.phrases")

        XCTAssertThrowsError(try store.addPhrase("会失败", scene: .medical, sub: "问诊")) { error in
            XCTAssertEqual(error as? YZPhraseError, YZPhraseError.saveFailed("模拟失败"))
        }
    }
}