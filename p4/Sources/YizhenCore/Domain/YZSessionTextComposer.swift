import Foundation

public enum YZSessionExportKind: Sendable, Equatable {
    case single
    case all
}

public struct YZSessionTextComposer: Sendable {
    public init() {}

    public func composeSingle(
        _ session: YZStoredSession,
        display: any YZSessionDisplayNameProviding,
        timeZone: TimeZone,
        exportTime: Date
    ) -> String {
        let scenarioName = resolvedName(display.displayName(forScenario: session.scenario), fallback: session.scenario)
        let phaseName = resolvedName(display.displayName(forPhase: session.phase), fallback: session.phase)

        var lines: [String] = [
            "译诊 · 会话记录",
            "场景：\(scenarioName)",
            "环节：\(phaseName)",
            "开始时间：\(format(session.startTime, timeZone: timeZone))",
            "结束时间：\(format(session.endTime, timeZone: timeZone))",
            "对话：",
        ]

        if session.sentences.isEmpty {
            lines.append("（无对话）")
        } else {
            for sentence in session.sentences {
                lines.append("\(sentence.speaker.displayName)：\(sanitized(sentence.text))")
            }
        }

        return lines.joined(separator: "\n")
    }

    public func composeAll(
        _ sessions: [YZStoredSession],
        display: any YZSessionDisplayNameProviding,
        timeZone: TimeZone,
        exportTime: Date
    ) -> String {
        var lines: [String] = [
            "译诊 · 全部会话记录",
            "导出时间：\(format(exportTime, timeZone: timeZone))",
            "会话数量：\(sessions.count)",
        ]

        if sessions.isEmpty {
            lines.append("暂无会话记录")
        } else {
            for (index, session) in sessions.enumerated() {
                if index > 0 {
                    lines.append("----------")
                }
                lines.append(
                    composeSingle(
                        session,
                        display: display,
                        timeZone: timeZone,
                        exportTime: exportTime
                    )
                )
            }
        }

        return lines.joined(separator: "\n")
    }

    public func suggestedFileName(
        kind: YZSessionExportKind,
        at date: Date,
        timeZone: TimeZone
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let prefix = kind == .single ? "译诊记录" : "译诊全部记录"
        return "\(prefix)_\(formatter.string(from: date)).txt"
    }

    private func resolvedName(_ name: String?, fallback: String) -> String {
        guard let name else { return fallback }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func format(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func sanitized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
}