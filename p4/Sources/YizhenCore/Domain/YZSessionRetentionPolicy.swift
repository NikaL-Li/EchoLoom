import Foundation

public struct YZSessionRetentionPolicy: Sendable {
    public static let `default` = YZSessionRetentionPolicy(
        maxRetained: YZSessionSnapshot.maxRetainedSessions,
        maxFileBytes: YZSessionSnapshot.maxFileBytes
    )

    public let maxRetained: Int
    public let maxFileBytes: Int

    public init(
        maxRetained: Int = YZSessionSnapshot.maxRetainedSessions,
        maxFileBytes: Int = YZSessionSnapshot.maxFileBytes
    ) {
        self.maxRetained = maxRetained
        self.maxFileBytes = maxFileBytes
    }

    public func isOlder(_ lhs: YZStoredSession, than rhs: YZStoredSession) -> Bool {
        lhs.isOrderedBefore(rhs)
    }

    /// 按「开始时间 → 结束时间 → 标识」升序淘汰至条数上限，返回被淘汰的标识。
    @discardableResult
    public func trim(_ sessions: inout [YZStoredSession]) -> [YZSessionID] {
        guard sessions.count > maxRetained else { return [] }

        let overflow = sessions.count - maxRetained
        let oldest = YZStoredSession.sortedAscending(sessions).prefix(overflow)
        let droppedIDs = Set(oldest.map(\.id))
        sessions.removeAll { droppedIDs.contains($0.id) }
        return oldest.map(\.id)
    }

    /// 持续淘汰最旧会话，直到满足文件字节上限或仅剩一条；最多迭代 20 次。
    @discardableResult
    public func trimForSize(
        _ sessions: inout [YZStoredSession],
        maxBytes: Int,
        encodedSize: ([YZStoredSession]) -> Int
    ) -> [YZSessionID] {
        var dropped: [YZSessionID] = []
        var iterations = 0

        while sessions.count > 1, iterations < YZSessionSnapshot.maxRetainedSessions {
            guard encodedSize(sessions) > maxBytes else { break }
            guard let oldest = YZStoredSession.sortedAscending(sessions).first else { break }
            sessions.removeAll { $0.id == oldest.id }
            dropped.append(oldest.id)
            iterations += 1
        }

        return dropped
    }
}