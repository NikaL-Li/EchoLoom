import Foundation

enum YZFormatting {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func statusLine(status: String, date: Date) -> String {
        "\(status) · \(time(date))"
    }

    static func directionWord(_ direction: YZMessageDirection) -> String {
        switch direction {
        case .mine: return "我说"
        case .other: return "对方说"
        }
    }

    static func cardLabel(sceneID: YZScene.ID, date: Date) -> String {
        let speaker = sceneID == "medical" ? "医生" : "对方"
        return "\(speaker) · \(time(date))"
    }

    static func cardAccessibilityLabel(_ message: YZMessage, sceneID: YZScene.ID) -> String {
        let footer: String
        if message.direction == .other {
            footer = cardLabel(sceneID: sceneID, date: message.createdAt)
        } else {
            footer = "\(message.statusText) \(time(message.createdAt))"
        }
        return "\(directionWord(message.direction))。\(message.text)。\(footer)。"
    }
}