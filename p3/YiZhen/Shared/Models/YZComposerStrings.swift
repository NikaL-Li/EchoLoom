import Foundation

enum YZComposerStrings {
    static let title = "我要说"
    static let close = "关闭"
    static let inputPlaceholder = "打字给对方看，Enter 发送"
    static let send = "发送给对方"
    static let note1 = "听不清？可在「我的」打开全程用文字。"
    static let note2 = "手语识别即将支持（占位）。"
    static let sentStatusText = "文字直达"
    static let inputAccessibilityLabel = "输入要发给对方看的文字"
    static let inputAccessibilityHint = "输入后按回车或点发送，最多 500 字"
}

enum YZComposerRules {
    static let maxLength = 500

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isSendable(_ text: String) -> Bool {
        let value = trimmed(text)
        return !value.isEmpty && value.count <= maxLength
    }

    static func normalizedSendText(_ text: String) -> String? {
        guard isSendable(text) else { return nil }
        return trimmed(text)
    }

    static func clamp(_ text: String) -> String {
        text.count <= maxLength ? text : String(text.prefix(maxLength))
    }
}