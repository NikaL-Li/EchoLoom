import Foundation

/// 纯文件 IO 抽象，不承载任何业务模型。
public protocol YZSessionFileSystem: Sendable {
    /// Application Support 根目录，不负责创建。
    func applicationSupportDirectory() throws -> URL

    func fileExists(at url: URL) -> Bool

    func readData(at url: URL) throws -> Data

    func createDirectory(at url: URL) throws

    /// 两阶段原子写：先写临时文件，再原子替换目标。失败时目标文件必须保持原样。
    func atomicallyWrite(_ data: Data, to url: URL) throws

    /// 设置数据保护与排除备份属性。失败不得影响数据可用性，因此不抛错。
    func applyProtection(to url: URL)

    func removeItemIfExists(at url: URL)

    func fileSize(at url: URL) -> Int?
}