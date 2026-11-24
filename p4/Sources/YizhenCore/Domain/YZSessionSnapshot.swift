import Foundation

/// 不可变会话快照。累计次数在构造时强制不小于当前条数。
public struct YZSessionSnapshot: Sendable, Equatable {
    public static let maxRetainedSessions = 20
    public static let maxFileBytes = 2 * 1024 * 1024
    public static let maxSessionBytes = 2 * 1024 * 1024

    public var sessions: [YZStoredSession]
    public var totalSavedCount: Int

    public init(sessions: [YZStoredSession], totalSavedCount: Int) {
        self.sessions = sessions
        self.totalSavedCount = max(totalSavedCount, sessions.count)
    }

    public static let empty = YZSessionSnapshot(sessions: [], totalSavedCount: 0)

    public func sortedDescending() -> [YZStoredSession] {
        YZStoredSession.sortedDescending(sessions)
    }

    public func sortedAscending() -> [YZStoredSession] {
        YZStoredSession.sortedAscending(sessions)
    }
}