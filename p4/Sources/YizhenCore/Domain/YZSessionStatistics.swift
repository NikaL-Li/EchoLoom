import Foundation

public struct YZSessionStatistics: Sendable, Equatable {
    public let todayCount: Int
    public let last7DaysCount: Int
    public let thisMonthCount: Int
    public let totalCount: Int

    public init(todayCount: Int, last7DaysCount: Int, thisMonthCount: Int, totalCount: Int) {
        self.todayCount = todayCount
        self.last7DaysCount = last7DaysCount
        self.thisMonthCount = thisMonthCount
        self.totalCount = totalCount
    }

    public static let zero = YZSessionStatistics(
        todayCount: 0,
        last7DaysCount: 0,
        thisMonthCount: 0,
        totalCount: 0
    )
}