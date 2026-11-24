import Foundation

public enum YZSessionOperation: String, Sendable, Equatable {
    case load
    case save
    case delete
    case clear
    case statistics
    case export
}

/// 日志事件只允许承载错误码、操作、条数、耗时与版本号，禁止任何对话内容。
public struct YZSessionLogEvent: Sendable, Equatable {
    public let errorCode: String?
    public let operation: YZSessionOperation
    public let count: Int?
    public let durationMs: Int?
    public let schemaVersion: Int?

    public init(
        errorCode: String? = nil,
        operation: YZSessionOperation,
        count: Int? = nil,
        durationMs: Int? = nil,
        schemaVersion: Int? = nil
    ) {
        self.errorCode = errorCode
        self.operation = operation
        self.count = count
        self.durationMs = durationMs
        self.schemaVersion = schemaVersion
    }
}

extension YZSessionLogEvent: CustomStringConvertible {
    public var description: String {
        var parts: [String] = ["operation=\(operation.rawValue)"]
        if let errorCode { parts.append("error=\(errorCode)") }
        if let count { parts.append("count=\(count)") }
        if let durationMs { parts.append("durationMs=\(durationMs)") }
        if let schemaVersion { parts.append("schemaVersion=\(schemaVersion)") }
        return "YZSessionLogEvent(\(parts.joined(separator: ",")))"
    }
}

public protocol YZSessionStoreLogger: Sendable {
    func log(_ event: YZSessionLogEvent)
}

public struct YZSessionNullLogger: YZSessionStoreLogger {
    public init() {}

    public func log(_ event: YZSessionLogEvent) {}
}