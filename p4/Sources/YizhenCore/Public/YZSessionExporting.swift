import Foundation

public protocol YZSessionExporting: Sendable {
    /// 单条导出；标识不存在返回 .notFound，不生成空文本冒充成功。
    func exportSession(id: YZSessionID) async -> YZExportResult

    /// 全部导出；无会话时输出「暂无会话记录」而非错误。按时间升序排列。
    func exportAll() async -> YZExportDocument
}