import Foundation

public struct YZExportDocument: Sendable, Equatable {
    public let text: String
    public let suggestedFileName: String

    public init(text: String, suggestedFileName: String) {
        self.text = text
        self.suggestedFileName = suggestedFileName
    }

    /// UTF-8 无 BOM 数据。行尾为 LF。
    public var utf8Data: Data {
        Data(text.utf8)
    }
}

public enum YZExportResult: Sendable, Equatable {
    case success(YZExportDocument)
    case notFound
}