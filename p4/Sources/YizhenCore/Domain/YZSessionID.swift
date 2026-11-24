import Foundation

/// 会话稳定标识。避免与场景/环节等字符串参数误用。
public struct YZSessionID:
    RawRepresentable,
    Hashable,
    Sendable,
    Comparable,
    ExpressibleByStringLiteral,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static func < (lhs: YZSessionID, rhs: YZSessionID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        rawValue
    }
}