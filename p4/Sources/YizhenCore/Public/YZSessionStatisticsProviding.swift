import Foundation

public protocol YZSessionStatisticsProviding: Sendable {
    /// 四项统计基于同一次读取快照，每次调用按当前日历重新计算。
    func statistics() async -> YZSessionStatistics

    /// 首页「今日对话」窄接口，口径与 statistics().todayCount 完全一致。
    func todayCount() async -> Int
}