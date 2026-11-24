import Foundation

/// 当前时间来源。测试可注入可前进的假时钟。
public protocol YZClockProvider: Sendable {
    func now() -> Date
}

public struct YZSystemClock: YZClockProvider {
    public init() {}

    public func now() -> Date {
        Date()
    }
}