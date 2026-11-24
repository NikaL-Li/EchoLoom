import Foundation

public struct YZStoredSession: Sendable, Equatable, Identifiable {
    public let id: YZSessionID
    public let scenario: String
    public let phase: String
    public let startTime: Date
    public let endTime: Date
    public let sentences: [YZStoredSentence]

    public init(
        id: YZSessionID,
        scenario: String,
        phase: String,
        startTime: Date,
        endTime: Date,
        sentences: [YZStoredSentence]
    ) {
        self.id = id
        self.scenario = scenario
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
        self.sentences = sentences
    }

    /// 唯一淘汰比较口径：开始时间升序 → 结束时间升序 → 标识字典序升序。
    public func isOrderedBefore(_ other: YZStoredSession) -> Bool {
        if startTime != other.startTime {
            return startTime < other.startTime
        }
        if endTime != other.endTime {
            return endTime < other.endTime
        }
        return id < other.id
    }

    public static func sortedAscending(_ sessions: [YZStoredSession]) -> [YZStoredSession] {
        sessions.sorted { lhs, rhs in
            if lhs.startTime != rhs.startTime {
                return lhs.startTime < rhs.startTime
            }
            if lhs.endTime != rhs.endTime {
                return lhs.endTime < rhs.endTime
            }
            return lhs.id < rhs.id
        }
    }

    public static func sortedDescending(_ sessions: [YZStoredSession]) -> [YZStoredSession] {
        sessions.sorted { lhs, rhs in
            if lhs.startTime != rhs.startTime {
                return lhs.startTime > rhs.startTime
            }
            if lhs.endTime != rhs.endTime {
                return lhs.endTime > rhs.endTime
            }
            return lhs.id < rhs.id
        }
    }
}