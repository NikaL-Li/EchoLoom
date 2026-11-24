import Foundation

/// P1 `YZSessionStoring` 的本地 JSON 实现。
/// 最多保留最近 20 条；读取失败返回空数组；写入失败保留旧文件。
final class YZFeatureSessionStore: YZSessionStoring {
    static let maxSessionCount = 20
    static let totalCountKey = "yz.sessions.totalSavedCount"

    static var savedTotalCount: Int {
        UserDefaults.standard.integer(forKey: totalCountKey)
    }

    private let fileURL: URL
    private let lock = NSLock()

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
    }

    func load() -> [YZSession] {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let sessions = try? decoder.decode([YZSession].self, from: data) else {
            return []
        }

        return Self.latest(sessions)
    }

    func save(_ sessions: [YZSession]) {
        lock.lock()
        defer { lock.unlock() }

        let cumulativeTotal = max(Self.savedTotalCount, sessions.count)
        UserDefaults.standard.set(cumulativeTotal, forKey: Self.totalCountKey)

        let latest = Self.latest(sessions)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(latest) else {
            return
        }

        let directory = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

            let temporaryURL = directory.appendingPathComponent(
                ".sessions-\(UUID().uuidString).json"
            )

            do {
                try data.write(to: temporaryURL, options: [])
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    _ = try FileManager.default.replaceItemAt(
                        fileURL,
                        withItemAt: temporaryURL
                    )
                } else {
                    try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
                }
            } catch {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
        } catch {
            // 写失败保留旧文件，不抛出、不崩溃。
        }
    }

    private static func latest(_ sessions: [YZSession]) -> [YZSession] {
        Array(sessions.sorted { $0.endedAt > $1.endedAt }.prefix(maxSessionCount))
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return base
            .appendingPathComponent("YiZhen", isDirectory: true)
            .appendingPathComponent("sessions.json", isDirectory: false)
    }
}