import Foundation

public enum YZSessionErrorCode: String, Sendable, Equatable {
    case invalidField = "SESSION_INVALID"
    case writeFailed = "SESSION_WRITE_FAILED"
    case notFound = "SESSION_NOT_FOUND"
    case decodeFailed = "SESSION_DECODE_FAILED"
}

/// 写操作错误。不包含路径、对话原文或 JSON 细节。
public enum YZSessionStoreError: Error, Sendable, Equatable {
    case invalid(field: YZSessionInvalidField)
    case writeFailed(underlyingCode: String?)
    case notFound(id: YZSessionID)

    public var code: YZSessionErrorCode {
        switch self {
        case .invalid:
            return .invalidField
        case .writeFailed:
            return .writeFailed
        case .notFound:
            return .notFound
        }
    }

    public var messageKey: String {
        switch self {
        case .invalid(let field):
            return "session.error.invalid.\(field.rawValue)"
        case .writeFailed:
            return "session.error.write_failed"
        case .notFound:
            return "session.error.not_found"
        }
    }
}