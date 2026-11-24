import Foundation

final class YZFeatureSessionStore: YZSessionStoring {
    static let maxSessionCount = 20

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
            var directoryURL = directory
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? directoryURL.setResourceValues(values)
            try data.write(to: fileURL, options: .atomic)
        } catch {
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
