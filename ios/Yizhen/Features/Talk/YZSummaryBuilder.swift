import Foundation

enum YZSummaryBuilder {
    struct Sentence: Equatable {
        let role: YZRole
        let text: String

        init(role: YZRole, text: String) {
            self.role = role
            self.text = text
        }
    }

    static let maximumItemCount = 3
    static let maximumCharacterCount = 70
    static let actionKeywords = ["去", "先", "再", "需要", "检查", "缴费", "取药", "复诊"]

    static func build(turns: [YZTurn], scene: SceneKind?) -> [String] {
        build(
            sentences: turns.map { Sentence(role: $0.role, text: $0.text) },
            scene: scene
        )
    }

    static func build(sentences: [Sentence], scene: SceneKind?) -> [String] {
        let prepared = sentences.map { Sentence(role: $0.role, text: normalized($0.text)) }
        let mineIndex = prepared.lastIndex { $0.role == .me && !$0.text.isEmpty }
        let otherIndex = prepared.lastIndex { $0.role == .other && !$0.text.isEmpty }
        let actionIndex = prepared.indices.reversed().first { index in
            index != mineIndex
                && index != otherIndex
                && !prepared[index].text.isEmpty
                && containsActionKeyword(prepared[index].text)
        }

        var items: [String] = []
        if let mineIndex {
            items.append(truncate(prepared[mineIndex].text))
        }
        if let otherIndex {
            items.append(truncate(prepared[otherIndex].text))
        }
        if let actionIndex {
            items.append(truncate(prepared[actionIndex].text))
        }
        return Array(items.prefix(maximumItemCount))
    }

    static func copyText(from items: [String]) -> String {
        items.enumerated()
            .map { index, item in "\(index + 1). \(item)" }
            .joined(separator: "\n")
    }

    private static func containsActionKeyword(_ text: String) -> Bool {
        actionKeywords.contains { text.contains($0) }
    }

    private static func normalized(_ raw: String) -> String {
        raw.split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    private static func truncate(_ text: String) -> String {
        guard text.count > maximumCharacterCount else { return text }
        return String(text.prefix(maximumCharacterCount)) + "…"
    }
}
