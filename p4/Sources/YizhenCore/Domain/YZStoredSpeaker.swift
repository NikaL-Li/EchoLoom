import Foundation

/// 内部说话人模型。未知值原样保留，避免二次保存改写数据。
public enum YZStoredSpeaker: Sendable, Equatable, Hashable {
    case me
    case other
    case unknown(String?)

    public var rawValue: String {
        switch self {
        case .me:
            return "me"
        case .other:
            return "other"
        case .unknown(let raw):
            return raw ?? "unknown"
        }
    }

    public var displayName: String {
        switch self {
        case .me:
            return "我"
        case .other:
            return "对方"
        case .unknown:
            return "未知"
        }
    }
}