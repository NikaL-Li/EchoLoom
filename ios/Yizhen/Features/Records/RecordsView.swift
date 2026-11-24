import SwiftUI

struct RecordsView: View {
    let sessions: [YZSession]
    let todaySessionCount: Int
    let totalSessionCount: Int
    let onSelectSession: (UUID) -> Void
    let onRequestStartConversation: () -> Void

    init(
        sessions: [YZSession],
        todaySessionCount: Int,
        totalSessionCount: Int,
        onSelectSession: @escaping (UUID) -> Void,
        onRequestStartConversation: @escaping () -> Void
    ) {
        self.sessions = sessions
        self.todaySessionCount = todaySessionCount
        self.totalSessionCount = totalSessionCount
        self.onSelectSession = onSelectSession
        self.onRequestStartConversation = onRequestStartConversation
    }

    private var statistics: YZRecordsStatistics {
        YZRecordsStatistics.calculate(
            sessions: sessions,
            todayCount: todaySessionCount,
            totalSavedCount: totalSessionCount
        )
    }

    private var rows: [YZRecordsRowModel] {
        sessions
            .sorted { $0.endedAt > $1.endedAt }
            .map { session in
                YZRecordsRowModel(
                    id: session.id,
                    session: session,
                    title: YZRecordsCopy.title(for: session),
                    timeText: YZRecordsCopy.timeText(session.startedAt),
                    sentenceCountText: YZRecordsCopy.sentenceCount(session.turns.count)
                )
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
                YZPageTitle(
                    title: YZRecordsCopy.pageTitle,
                    subtitle: YZRecordsCopy.pageSubtitle
                )

                YZRecordsStatisticsCardView(statistics: statistics)

                YZPrimaryButton(title: YZRecordsCopy.startConversation) {
                    onRequestStartConversation()
                }

                if sessions.isEmpty {
                    YZRecordsEmptyStateView()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(rows) { row in
                            YZRecordsRowView(row: row) {
                                onSelectSession(row.id)
                            }
                        }
                    }
                }

                Text(YZRecordsCopy.footer)
                    .font(YZRecordsFont.tag)
                    .foregroundStyle(YZRecordsStyle.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, YZTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, YZTheme.tabBottomInset)
            .yzContentWidth()
        }
        .scrollIndicators(.hidden)
    }
}
