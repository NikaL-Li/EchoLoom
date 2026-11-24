import SwiftUI

struct YZSessionHeaderView: View {
    let title: String
    let subtitle: String
    let canGenerateSummary: Bool
    let onBack: () -> Void
    let onGenerateSummary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(YZSessionCopy.back)
                    }
                    .font(YZTheme.fontPill)
                    .foregroundStyle(YZSessionStyle.primary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(YZSessionStyle.cardBackground, in: Capsule())
                    .overlay(
                        Capsule().stroke(
                            YZSessionStyle.separator,
                            lineWidth: YZTheme.highContrast ? 2 : 1
                        )
                    )
                }
                .buttonStyle(YZPressButtonStyle())
                .accessibilityLabel(YZSessionCopy.back)

                Spacer(minLength: 8)

                Button(action: onGenerateSummary) {
                    Text(YZSessionCopy.generateSummary)
                        .font(YZTheme.fontPill)
                        .foregroundStyle(YZSessionStyle.primary)
                        .padding(.horizontal, 14)
                        .frame(height: YZTheme.pillHeight)
                        .background(YZSessionStyle.primarySoft, in: Capsule())
                        .overlay {
                            if YZTheme.highContrast {
                                Capsule().stroke(Color.black, lineWidth: 2)
                            }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressButtonStyle())
                .disabled(!canGenerateSummary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(YZSessionFont.pageTitle)
                    .foregroundStyle(YZSessionStyle.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(YZSessionFont.caption)
                        .foregroundStyle(YZSessionStyle.textSecondary)
                }
            }
        }
    }
}

struct YZSessionSentenceCardView: View {
    let sentence: YZSentenceDisplayModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(sentence.speakerText)
                        .font(YZSessionFont.caption)
                        .foregroundStyle(YZSessionStyle.textSecondary)

                    Spacer(minLength: 8)

                    if !sentence.status.isEmpty {
                        Text(sentence.status)
                            .font(YZSessionFont.tag)
                            .foregroundStyle(
                                sentence.status == "播报失败"
                                    ? YZSessionStyle.danger
                                    : YZSessionStyle.textTertiary
                            )
                    }
                }

                Text(sentence.text)
                    .font(YZSessionFont.body)
                    .foregroundStyle(YZSessionStyle.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                YZSessionStyle.cardBackground,
                in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                    .stroke(
                        YZTheme.highContrast ? Color.black : YZSessionStyle.separator,
                        lineWidth: YZTheme.highContrast ? 2 : 1
                    )
            }
            .overlay(alignment: sentence.role == .me ? .leading : .trailing) {
                Rectangle()
                    .fill(
                        sentence.role == .me
                            ? YZSessionStyle.primaryFill
                            : YZSessionStyle.successFill
                    )
                    .frame(width: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous))
            .yzCardShadow()
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(sentence.speakerText)，\(sentence.text)")
        .accessibilityHint("轻点看全屏大字")
    }
}

struct YZSessionSummaryCardView: View {
    let state: YZSessionSummaryUIState
    let onRetry: () -> Void
    let onCollapse: () -> Void

    @State private var copySucceeded = false
    @State private var copyFailed = false

    init(
        state: YZSessionSummaryUIState,
        onRetry: @escaping () -> Void,
        onCollapse: @escaping () -> Void
    ) {
        self.state = state
        self.onRetry = onRetry
        self.onCollapse = onCollapse
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(YZSessionCopy.summaryTitle)
                    .font(YZSessionFont.summaryTitle)
                    .foregroundStyle(YZSessionStyle.textPrimary)

                Spacer(minLength: 8)

                YZPillButton(
                    title: YZSessionCopy.collapse,
                    size: .small,
                    action: onCollapse
                )
            }

            content

            if let lines = summaryLines {
                YZPillButton(
                    title: copySucceeded
                        ? YZSessionCopy.copied
                        : (copyFailed ? YZSessionCopy.copyFailed : YZSessionCopy.copy),
                    size: .small
                ) {
                    let result = YZClipboard.copy(YZSummaryBuilder.copyText(from: lines))
                    copySucceeded = result
                    copyFailed = !result
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            YZSessionStyle.primarySoft,
            in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
        )
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .generating:
            HStack(spacing: 8) {
                ProgressView()
                Text(YZSessionCopy.summaryGenerating)
                    .font(YZSessionFont.body)
                    .foregroundStyle(YZSessionStyle.textSecondary)
            }

        case .content(let lines):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.indices), id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("·")
                            .font(YZSessionFont.body)
                            .foregroundStyle(YZSessionStyle.textSecondary)
                        Text(lines[index])
                            .font(YZSessionFont.body)
                            .foregroundStyle(YZSessionStyle.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .empty:
            Text(YZSessionCopy.summaryEmpty)
                .font(YZSessionFont.body)
                .foregroundStyle(YZSessionStyle.textSecondary)

        case .failed:
            HStack(spacing: 12) {
                Text(YZSessionCopy.summaryFailed)
                    .font(YZSessionFont.body)
                    .foregroundStyle(YZSessionStyle.textSecondary)
                YZPillButton(
                    title: YZSessionCopy.retry,
                    size: .small,
                    action: onRetry
                )
            }

        case .unavailable:
            Text(YZSessionCopy.summaryUnavailable)
                .font(YZSessionFont.body)
                .foregroundStyle(YZSessionStyle.textSecondary)
        }
    }

    private var summaryLines: [String]? {
        if case .content(let lines) = state {
            return lines
        }
        return nil
    }
}
