import Foundation

/// 默认文件系统实现。使用临时文件 + replaceItemAt 完成原子替换。
public struct YZDefaultFileSystem: YZSessionFileSystem {
    private let baseDirectory: URL?

    public init(baseDirectory: URL? = nil) {
        self.baseDirectory = baseDirectory
    }

    public func applicationSupportDirectory() throws -> URL {
        if let baseDirectory {
            return baseDirectory
        }
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw YZDefaultFileSystemError.applicationSupportUnavailable
        }
        return url
    }

    public func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func atomicallyWrite(_ data: Data, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        let temporaryURL = directory.appendingPathComponent(
            ".\(url.lastPathComponent).tmp-\(UUID().uuidString)",
            isDirectory: false
        )

        do {
            try data.write(to: temporaryURL, options: [])
            if fileExists(at: url) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: temporaryURL)
            } else {
                try FileManager.default.moveItem(at: temporaryURL, to: url)
            }
        } catch {
            removeItemIfExists(at: temporaryURL)
            throw error
        }
    }

    public func applyProtection(to url: URL) {
        #if os(iOS)
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        try? FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
        #endif
    }

    public func removeItemIfExists(at url: URL) {
        guard fileExists(at: url) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    public func fileSize(at url: URL) -> Int? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber else {
            return nil
        }
        return size.intValue
    }
}

public enum YZDefaultFileSystemError: Error, Sendable, Equatable {
    case applicationSupportUnavailable
}