import Foundation

enum YZSummaryBuilder {
    struct Sentence: Equatable {
        let direction: YZMessageDirection
        let text: String

        init(direction: YZMessageDirection, text: String) {
            self.direction = direction
            self.text = text
        }
    }

    static let maximumItemCount = 3
    static let maximumCharacterCount = 70
    static let actionKeywords = ["去", "先", "再", "需要", "检查", "缴费", "取药", "复诊"]

    static func build(sentences: [Sentence], scene: YZScene?) -> [String] {
        let prepared = sentences.map { Sentence(direction: $0.direction, text: normalized($0.text)) }
        let mineIndex = prepared.lastIndex { $0.direction == .mine && !$0.text.isEmpty }
        let otherIndex = prepared.lastIndex { $0.direction == .other && !$0.text.isEmpty }
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

    static func build(messages: [YZMessage], scene: YZScene?) -> [String] {
        build(
            sentences: messages.map { Sentence(direction: $0.direction, text: $0.text) },
            scene: scene
        )
    }

    static func copyText(from items: [String]) -> String {
        items.enumerated()
            .map { index, item in "\(index + 1). \(item)" }
            .joined(separator: " ")
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