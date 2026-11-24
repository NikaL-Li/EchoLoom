import SwiftUI

struct YZRecordsStatisticsCardView: View {
    let statistics: YZRecordsStatistics

    var body: some View {
        YZCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(YZRecordsCopy.today)
                            .font(YZRecordsFont.caption)
                            .foregroundStyle(YZRecordsStyle.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(statistics.todayCount)")
                                .font(YZRecordsFont.summaryNumber)
                                .foregroundStyle(YZRecordsStyle.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)

                            Text("次")
                                .font(YZRecordsFont.caption)
                                .foregroundStyle(YZRecordsStyle.textSecondary)
                        }
                    }

                    Spacer(minLength: 12)

                    Circle()
                        .fill(YZRecordsStyle.successFill)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(YZTheme.highContrast ? .black : .white)
                        )
                        .overlay {
                            if YZTheme.highContrast {
                                Circle().stroke(Color.black, lineWidth: 2)
                            }
                        }
                        .accessibilityHidden(true)
                }

                HStack(spacing: 12) {
                    YZRecordsMetricTile(
                        title: YZRecordsCopy.last7Days,
                        value: statistics.last7DaysCount
                    )
                    YZRecordsMetricTile(
                        title: YZRecordsCopy.thisMonth,
                        value: statistics.thisMonthCount
                    )
                    YZRecordsMetricTile(
                        title: YZRecordsCopy.total,
                        value: statistics.totalCount
                    )
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "今天 \(statistics.todayCount) 次，近 7 天 \(statistics.last7DaysCount) 次，本月 \(statistics.thisMonthCount) 次，累计 \(statistics.totalCount) 次"
        )
    }
}

struct YZRecordsRowView: View {
    let row: YZRecordsRowModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(row.title)
                        .font(YZRecordsFont.rowTitle)
                        .foregroundStyle(YZRecordsStyle.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(row.timeText)
                        .font(YZRecordsFont.tag)
                        .foregroundStyle(YZRecordsStyle.textTertiary)
                }

                Spacer(minLength: 8)

                Text(row.sentenceCountText)
                    .font(YZRecordsFont.tag)
                    .foregroundStyle(YZRecordsStyle.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(YZRecordsStyle.mutedSurface)
                    .clipShape(Capsule())
                    .overlay {
                        if YZTheme.highContrast {
                            Capsule().stroke(Color.black, lineWidth: 2)
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: YZTheme.rowHeight, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                YZRecordsStyle.cardBackground,
                in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
            )
            .overlay {
                if YZTheme.highContrast {
                    RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                        .stroke(Color.black, lineWidth: 2)
                }
            }
            .yzCardShadow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.title)，\(row.timeText)，\(row.sentenceCountText)")
    }
}

struct YZRecordsEmptyStateView: View {
    var body: some View {
        YZCard {
            VStack(spacing: 14) {
                Circle()
                    .fill(YZRecordsStyle.mutedSurface)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(YZRecordsStyle.textTertiary)
                    )
                    .overlay {
                        if YZTheme.highContrast {
                            Circle().stroke(Color.black, lineWidth: 2)
                        }
                    }
                    .accessibilityHidden(true)

                Text(YZRecordsCopy.emptyTitle)
                    .font(YZRecordsFont.rowTitle)
                    .foregroundStyle(YZRecordsStyle.textPrimary)
                    .multilineTextAlignment(.center)

                Text(YZRecordsCopy.emptyMessage)
                    .font(YZRecordsFont.caption)
                    .foregroundStyle(YZRecordsStyle.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct YZRecordsMetricTile: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(YZRecordsFont.caption)
                .foregroundStyle(YZRecordsStyle.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(value)")
                .font(YZRecordsFont.metricValue)
                .foregroundStyle(YZRecordsStyle.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            YZTheme.bg,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
    }
}