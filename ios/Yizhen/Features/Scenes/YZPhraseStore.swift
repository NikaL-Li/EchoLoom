import Foundation

enum YZPhraseLimit {
    static let maxLength = 60
}

enum YZPhraseError: LocalizedError, Equatable {
    case emptyText
    case tooLong(limit: Int)
    case duplicate
    case notFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "内容不能为空。"
        case .tooLong(let limit):
            return "最多 \(limit) 个字。"
        case .duplicate:
            return "已经有一句一样的了。"
        case .notFound:
            return "没有找到这句常用语。"
        case .saveFailed(let reason):
            return "保存失败：\(reason)"
        }
    }
}

protocol YZKeyValueStore {
    func read(_ key: String) -> Data?
    func write(_ data: Data, for key: String) throws
}

struct YZUserDefaultsStore: YZKeyValueStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func read(_ key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func write(_ data: Data, for key: String) throws {
        defaults.set(data, forKey: key)
        guard defaults.data(forKey: key) == data else {
            throw YZPhraseError.saveFailed("写入后校验不一致")
        }
    }
}

protocol YZCustomPhraseStoring {
    func customPhrases(scene: SceneKind, sub: String) throws -> [String]
    func allCustomPhrases() throws -> [String: [String]]
    func addPhrase(_ text: String, scene: SceneKind, sub: String) throws
    func updatePhrase(_ original: String, to text: String, scene: SceneKind, sub: String) throws
    func deletePhrase(_ text: String, scene: SceneKind, sub: String) throws
}

final class YZUserDefaultsPhraseStore: YZCustomPhraseStoring {
    static let storageKey = "yizhen.myPhrases.v1"

    private let store: any YZKeyValueStore
    private let key: String

    init(
        store: any YZKeyValueStore = YZUserDefaultsStore(),
        key: String = YZUserDefaultsPhraseStore.storageKey
    ) {
        self.store = store
        self.key = key
    }

    static func groupKey(scene: SceneKind, sub: String) -> String {
        "\(scene.rawValue)|\(sub)"
    }

    func allCustomPhrases() throws -> [String: [String]] {
        loadMap()
    }

    func customPhrases(scene: SceneKind, sub: String) throws -> [String] {
        loadMap()[Self.groupKey(scene: scene, sub: sub)] ?? []
    }

    func addPhrase(_ text: String, scene: SceneKind, sub: String) throws {
        let value = try validated(text)
        var map = loadMap()
        let group = Self.groupKey(scene: scene, sub: sub)
        var list = map[group] ?? []

        guard !list.contains(value) else {
            throw YZPhraseError.duplicate
        }

        list.append(value)
        map[group] = list
        try saveMap(map)
    }

    func updatePhrase(_ original: String, to text: String, scene: SceneKind, sub: String) throws {
        let old = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = try validated(text)
        var map = loadMap()
        let group = Self.groupKey(scene: scene, sub: sub)
        var list = map[group] ?? []

        guard let index = list.firstIndex(of: old) else {
            throw YZPhraseError.notFound
        }
        if value == old { return }

        guard !list.contains(value) else {
            throw YZPhraseError.duplicate
        }

        list[index] = value
        map[group] = list
        try saveMap(map)
    }

    func deletePhrase(_ text: String, scene: SceneKind, sub: String) throws {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var map = loadMap()
        let group = Self.groupKey(scene: scene, sub: sub)
        var list = map[group] ?? []

        guard let index = list.firstIndex(of: value) else {
            throw YZPhraseError.notFound
        }

        list.remove(at: index)
        if list.isEmpty {
            map.removeValue(forKey: group)
        } else {
            map[group] = list
        }
        try saveMap(map)
    }

    private func validated(_ text: String) throws -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw YZPhraseError.emptyText }
        guard value.count <= YZPhraseLimit.maxLength else {
            throw YZPhraseError.tooLong(limit: YZPhraseLimit.maxLength)
        }
        return value
    }

    private func loadMap() -> [String: [String]] {
        guard let data = store.read(key), !data.isEmpty else { return [:] }
        guard let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }

        var cleaned: [String: [String]] = [:]
        for (group, texts) in decoded {
            let list = texts
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !list.isEmpty {
                cleaned[group] = list
            }
        }
        return cleaned
    }

    private func saveMap(_ map: [String: [String]]) throws {
        do {
            let data = try JSONEncoder().encode(map)
            try store.write(data, for: key)
        } catch let error as YZPhraseError {
            throw error
        } catch {
            throw YZPhraseError.saveFailed(error.localizedDescription)
        }
    }
}
