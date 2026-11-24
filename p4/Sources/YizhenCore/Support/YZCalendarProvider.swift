import Foundation

/// 日历来源。每次查询必须返回当下 Calendar.current，禁止跨调用缓存。
public protocol YZCalendarProvider: Sendable {
    func currentCalendar() -> Calendar
}

public struct YZSystemCalendarProvider: YZCalendarProvider {
    public init() {}

    public func currentCalendar() -> Calendar {
        Calendar.current
    }
}