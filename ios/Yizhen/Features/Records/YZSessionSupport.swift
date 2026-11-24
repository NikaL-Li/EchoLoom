import Foundation
import SwiftUI

enum YZSessionStyle {
    static var pageBackground: Color { YZTheme.bg }
    static var cardBackground: Color { YZTheme.card }
    static var textPrimary: Color { YZTheme.ink }
    static var textSecondary: Color { YZTheme.ink2 }
    static var textTertiary: Color { YZTheme.ink3 }
    static var separator: Color { YZTheme.line }
    static var primary: Color { YZTheme.blue }
    static var primarySoft: Color { YZTheme.blueSoft }
    static var mutedSurface: Color { YZTheme.bg }
    static var successFill: Color { YZTheme.greenFill }
    static var onPrimary: Color { .white }
}

enum YZSessionFont {
    static var pageTitle: Font { YZTheme.fontPageTitle }
    static var body: Font { YZTheme.fontBody }
    static var caption: Font { YZTheme.fontCaption }
    static var tag: Font { YZTheme.fontTag }
    static var button: Font { YZTheme.fontButton }
    static var summaryTitle: Font { YZTheme.fontRowTitle }

    static var largeBody: Font {
        .system(size: 30 * min(YZTheme.scale, 1.5), weight: .medium)
    }
}

enum YZSessionCopy {
    static let generateSummary = "生成要点"
    static let summaryTitle = "要点"
    static let collapse = "收起"
    static let copy = "复制"
    static let copied = "已复制要点"
    static let copyFailed = "复制失败，请稍后重试"
    static let closeLargeText = "关闭大字"
    static let emptySentences = "这次没有留下句子"
    static let back = "返回"
    static let summaryGenerating = "正在生成要点…"
    static let summaryEmpty = "暂无可归纳的内容"
    static let summaryFailed = "要点生成失败，请重试"
    static let summaryUnavailable = "要点生成暂不可用"
    static let retry = "重试"
    static let emptyText = "（空内容）"

    static func title(for session: YZSession) -> String {
        "\(session.scene.rawValue) · \(session.subScene)"
    }

    static func subtitle(for session: YZSession) -> String {
        "\(timeFormatter.string(from: session.startedAt)) · \(session.turns.count) 句"
    }

    static func speakerText(_ role: YZRole) -> String {
        switch role {
        case .me:
            return "我"
        case .other:
            return "对方"
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()
}

struct YZSentenceDisplayModel: Identifiable {
    let id: Int
    let role: YZRole
    let speakerText: String
    let text: String
    let status: String
}

enum YZSessionSummaryResult: Equatable {
    case content([String])
    case empty
    case failed
    case unavailable
}

protocol YZSessionSummaryProviding {
    func summary(for session: YZSession) async -> YZSessionSummaryResult
}

struct YZDefaultSessionSummaryProvider: YZSessionSummaryProviding {
    func summary(for session: YZSession) async -> YZSessionSummaryResult {
        let items = YZSummaryBuilder.build(turns: session.turns, scene: session.scene)
        return items.isEmpty ? .empty : .content(items)
    }
}

enum YZSessionSummaryUIState: Equatable {
    case hidden
    case generating
    case content([String])
    case empty
    case failed
    case unavailable
}

func yzSentenceModels(for session: YZSession) -> [YZSentenceDisplayModel] {
    session.turns.enumerated().map { index, turn in
        let text = turn.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return YZSentenceDisplayModel(
            id: index,
            role: turn.role,
            speakerText: YZSessionCopy.speakerText(turn.role),
            text: text.isEmpty ? YZSessionCopy.emptyText : turn.text,
            status: turn.status
        )
    }
}

enum YZSessionTextExporter {
    static func text(for session: YZSession) -> String {
        var lines: [String] = []
        lines.append("译诊 · \(session.title)")
        lines.append("\(dateFormatter.string(from: session.startedAt)) — \(dateFormatter.string(from: session.endedAt))")
        lines.append("共 \(session.turns.count) 句")
        lines.append("")
        for turn in session.turns {
            let who = turn.role == .me ? "我" : "对方"
            lines.append("\(who)：\(turn.text)")
        }
        return lines.joined(separator: "\n")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}
