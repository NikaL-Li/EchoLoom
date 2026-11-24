import Foundation
import YizhenContract

/// P1 YZSessionStoring 的占位协议：语义锁定，签名待 P1 最终交付后由适配层承接。
public protocol YZSessionStoring: Sendable {
    /// 读取全部会话，按开始时间倒序；永不抛出，文件缺失/损坏返回空数组。
    func sessions() async -> [YZSession]

    /// 新增或按标识更新；返回成功、校验失败或写入失败。
    func save(_ session: YZSessionDraft) async -> YZSessionSaveResult

    func delete(id: YZSessionID) async -> YZSessionDeleteResult

    func clearAll() async -> YZSessionClearResult
}