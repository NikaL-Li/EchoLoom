import Foundation
import YizhenContract

/// P1 协议 → 本组件语义的单向适配位。
/// 硬约束：不做校验、不计算统计、不拼接文本；读取异常吞掉并返回空；不暴露 URL/Data/JSON。
public struct YZSessionStoringAdapter: Sendable {
    private let core: YZSessionStore

    public init(core: YZSessionStore) {
        self.core = core
    }

    public func sessions() async -> [YZSession] {
        await core.sessions()
    }

    public func save(_ session: YZSessionDraft) async -> YZSessionSaveResult {
        await core.save(session)
    }

    public func delete(id: YZSessionID) async -> YZSessionDeleteResult {
        await core.delete(id: id)
    }

    public func clearAll() async -> YZSessionClearResult {
        await core.clearAll()
    }
}