import Foundation
import SwiftUI

enum YZRecordsStyle {
    static var pageBackground: Color { YZTheme.bg }
    static var cardBackground: Color { YZTheme.card }
    static var textPrimary: Color { YZTheme.ink }
    static var textSecondary: Color { YZTheme.ink2 }
    static var textTertiary: Color { YZTheme.ink3 }
    static var separator: Color { YZTheme.line }
    static var primary: Color { YZTheme.blue }
    static var primaryFill: Color { YZTheme.blueFill }
    static var primarySoft: Color { YZTheme.blueSoft }
    static var mutedSurface: Color { YZTheme.bg }
    static var successFill: Color { YZTheme.greenFill }
    static var danger: Color { YZTheme.danger }
    static var shadow: Color { YZTheme.shadowColor }
}

enum YZRecordsFont {
    static var pageTitle: Font { YZTheme.fontPageTitle }
    static var pageSubtitle: Font { YZTheme.fontCaption }
    static var rowTitle: Font { YZTheme.fontRowTitle }
    static var body: Font { YZTheme.fontBody }
    static var caption: Font { YZTheme.fontCaption }
    static var tag: Font { YZTheme.fontTag }
    static var button: Font { YZTheme.fontButton }

    static var summaryNumber: Font {
        .system(size: 56 * min(YZTheme.scale, 1.3), weight: .bold, design: .rounded)
    }

    static var metricValue: Font {
        .system(size: 22 * min(YZTheme.scale, 1.4), weight: .semibold)
    }
}

enum YZRecordsCopy {
    static let pageTitle = "每一次对话，都算数"
    static let pageSubtitle = "记下沟通的痕迹，也记得好好休息。"
    static let today = "今天"
    static let last7Days = "近 7 天"
    static let thisMonth = "本月"
    static let total = "累计"
    static let startConversation = "+ 开始新的对话"
    static let emptyTitle = "从第一次对话开始"
    static let emptyMessage = "完成一次对话后，这里会留下场景、时间和要点。"
    static let footer = "本机记录 · 暂不云端同步"

    static func title(for session: YZSession) -> String {
        "\(session.scene.rawValue) · \(session.subScene)"
    }

    static func timeText(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func sentenceCount(_ count: Int) -> String {
        "\(count) 句"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()
}

struct YZRecordsStatistics: Equatable {
    let todayCount: Int
    let last7DaysCount: Int
    let thisMonthCount: Int
    let totalCount: Int

    static func calculate(
        sessions: [YZSession],
        todayCount: Int,
        totalSavedCount: Int = 0,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> YZRecordsStatistics {
        let todayStart = calendar.startOfDay(for: now)

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart),
              let last7Start = calendar.date(byAdding: .day, value: -6, to: todayStart) else {
            return YZRecordsStatistics(
                todayCount: todayCount,
                last7DaysCount: 0,
                thisMonthCount: 0,
                totalCount: max(totalSavedCount, sessions.count)
            )
        }

        let monthInterval = calendar.dateInterval(of: .month, for: now)

        var last7DaysCount = 0
        var thisMonthCount = 0

        for session in sessions {
            let endedAt = session.endedAt
            if endedAt >= last7Start && endedAt < tomorrow {
                last7DaysCount += 1
            }
            if let monthInterval, monthInterval.contains(endedAt) {
                thisMonthCount += 1
            }
        }

        return YZRecordsStatistics(
            todayCount: todayCount,
            last7DaysCount: last7DaysCount,
            thisMonthCount: thisMonthCount,
            totalCount: max(totalSavedCount, sessions.count)
        )
    }
}

struct YZRecordsRowModel: Identifiable {
    let id: UUID
    let session: YZSession
    let title: String
    let timeText: String
    let sentenceCountText: String
}