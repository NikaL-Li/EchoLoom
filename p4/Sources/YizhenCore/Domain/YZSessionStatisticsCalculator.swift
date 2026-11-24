import Foundation

public struct YZSessionStatisticsCalculator: Sendable {
    public init() {}

    /// 四项统计只依赖传入的 now 与 calendar，每次调用现算，不缓存。
    public func calculate(
        snapshot: YZSessionSnapshot,
        now: Date,
        calendar: Calendar
    ) -> YZSessionStatistics {
        let todayStart = calendar.startOfDay(for: now)
        let monthComponents = calendar.dateComponents([.year, .month], from: now)

        guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart),
              let last7DaysStart = calendar.date(byAdding: .day, value: -6, to: todayStart),
              let monthStart = calendar.date(from: monthComponents),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return YZSessionStatistics(
                todayCount: 0,
                last7DaysCount: 0,
                thisMonthCount: 0,
                totalCount: snapshot.totalSavedCount
            )
        }

        var todayCount = 0
        var last7DaysCount = 0
        var thisMonthCount = 0

        for session in snapshot.sessions {
            let start = session.startTime
            if start >= todayStart && start < tomorrowStart {
                todayCount += 1
            }
            if start >= last7DaysStart && start < tomorrowStart {
                last7DaysCount += 1
            }
            if start >= monthStart && start < nextMonthStart {
                thisMonthCount += 1
            }
        }

        return YZSessionStatistics(
            todayCount: todayCount,
            last7DaysCount: last7DaysCount,
            thisMonthCount: thisMonthCount,
            totalCount: snapshot.totalSavedCount
        )
    }
}