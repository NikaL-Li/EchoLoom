import Foundation

public enum YZSessionLoadEmptyReason: String, Sendable, Equatable {
    case fileNotFound
    case unreadable
    case corrupted
}

public enum YZSessionLoadOutcome: Sendable, Equatable {
    case loaded(snapshot: YZSessionSnapshot, droppedCount: Int)
    case empty(reason: YZSessionLoadEmptyReason)
}

public struct YZSessionFileRepository: Sendable {
    public static let directoryName = "YiZhen"
    public static let fileName = "sessions.json"

    private let fileSystem: any YZSessionFileSystem
    private let codec: YZSessionFileCodec

    public init(
        fileSystem: any YZSessionFileSystem = YZDefaultFileSystem(),
        codec: YZSessionFileCodec = YZSessionFileCodec()
    ) {
        self.fileSystem = fileSystem
        self.codec = codec
    }

    /// 固定路径：Application Support/YiZhen/sessions.json。
    public func fileURL() throws -> URL {
        try fileSystem.applicationSupportDirectory()
            .appendingPathComponent(Self.directoryName, isDirectory: true)
            .appendingPathComponent(Self.fileName, isDirectory: false)
    }

    /// 读取永不抛错，也不创建目录或文件。
    public func load() -> YZSessionLoadOutcome {
        let url: URL
        do {
            url = try fileURL()
        } catch {
            return .empty(reason: .unreadable)
        }

        guard fileSystem.fileExists(at: url) else {
            return .empty(reason: .fileNotFound)
        }

        guard let data = try? fileSystem.readData(at: url) else {
            return .empty(reason: .unreadable)
        }

        guard !data.isEmpty else {
            return .empty(reason: .corrupted)
        }

        switch codec.decode(data) {
        case .decoded(let snapshot, let droppedCount, _):
            return .loaded(snapshot: snapshot, droppedCount: droppedCount)
        case .corrupted:
            return .empty(reason: .corrupted)
        }
    }

    /// 首次保存时才创建目录；写入成功后设置保护属性（属性失败不影响数据）。
    @discardableResult
    public func save(_ snapshot: YZSessionSnapshot) throws -> Int {
        let url = try fileURL()
        try fileSystem.createDirectory(at: url.deletingLastPathComponent())
        let data = try codec.encode(snapshot)
        try fileSystem.atomicallyWrite(data, to: url)
        fileSystem.applyProtection(to: url)
        return data.count
    }

    public func encodedSize(of snapshot: YZSessionSnapshot) throws -> Int {
        try codec.encode(snapshot).count
    }

    public func encodedSize(of session: YZStoredSession) throws -> Int {
        try codec.encodedSize(of: session)
    }
}