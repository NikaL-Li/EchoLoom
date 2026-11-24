import Foundation

enum YZTextRules {
    static let messageMaxLength = 500
    static let statusMaxLength = 20
    static let sceneNameRange = 2...6
}

enum YZMessageValidator {
    static func normalizedDirection(_ raw: String?) -> YZMessageDirection {
        YZMessageDirection(rawValue: raw ?? "") ?? .mine
    }

    static func normalizedText(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count > YZTextRules.messageMaxLength {

            return String(trimmed.prefix(YZTextRules.messageMaxLength))
        }
        return trimmed
    }

    static func normalizedStatus(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= YZTextRules.statusMaxLength else {
            return String(trimmed.prefix(YZTextRules.statusMaxLength))
        }
        return trimmed
    }

    static func normalize(_ messages: [YZMessage]) -> [YZMessage] {
        messages
            .filter { normalizedText($0.text) != nil }
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.createdAt == rhs.element.createdAt {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.createdAt < rhs.element.createdAt
            }
            .map { pair in
                let message = pair.element
                let text = normalizedText(message.text) ?? ""
                let status = normalizedStatus(message.statusText)
                if text == message.text && status == message.statusText {
                    return message
                }
                return YZMessage(
                    id: message.id,
                    direction: message.direction,
                    text: text,
                    statusText: status,
                    createdAt: message.createdAt,
                    replayable: message.replayable,
                    copyable: message.copyable,
                    isKeyPoint: message.isKeyPoint
                )
            }
    }
}

enum YZSceneValidator {
    static func hasSingleSelection(_ scenes: [YZScene]) -> Bool {
        scenes.filter(\.isSelected).count == 1
    }

}

enum YZPhaseValidator {
    static func hasAtMostOneCurrent(_ phases: [YZPhase]) -> Bool {
        phases.filter(\.isCurrent).count <= 1
    }
}