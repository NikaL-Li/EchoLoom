import SwiftUI

struct SayListView: View {
    let context: SayListContext

    @Environment(\.yzTheme) private var theme

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if context.phrases.isEmpty {
                    Text(context.emptyText)
                        .font(theme.typography.font(.caption))
                        .foregroundStyle(theme.colors.textWeak)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .accessibilityIdentifier(AccessibilityID.phraseEmpty)
                } else {
                    ForEach(context.phrases) { phrase in
                        row(phrase)
                    }
                    footer
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .id(context.phaseName + "|" + (context.phrases.first?.id ?? "empty") + "|\(context.phrases.count)")
        .accessibilityIdentifier(AccessibilityID.phraseList)
    }

    private func row(_ phrase: YZPhrase) -> some View {
        Button {
            context.onUse(phrase.id)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: theme.metrics.size.sayIcon, weight: .regular))
                    .foregroundStyle(theme.colors.sayRowIcon)
                    .frame(width: theme.metrics.size.sayIcon, height: theme.metrics.size.sayIcon)

                VStack(alignment: .leading, spacing: 4) {
                    Text(phrase.text)
                        .font(theme.typography.font(.saySentence))
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !context.phaseName.isEmpty {
                        Text(context.phaseName)
                            .font(theme.typography.font(.sayMeta))
                            .foregroundStyle(theme.colors.sayMetaText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Text("待播")
                    .font(theme.typography.font(.sayMeta))
                    .foregroundStyle(theme.colors.sayMetaText)
                    .lineLimit(1)
            }
            .padding(.horizontal, theme.metrics.spacing.sayRowPaddingH)
            .padding(.vertical, theme.metrics.spacing.sayRowPaddingV)
            .frame(minHeight: theme.metrics.size.sayRowMinHeight, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.colors.separator)
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())

        .accessibilityLabel(Text("\(phrase.text)，\(context.phaseName)，待播"))
        .accessibilityHint("播报功能筹备中")
        .accessibilityIdentifier(AccessibilityID.phraseRow(phrase.id))
    }

    private var footer: some View {
        Text("共 \(context.phrases.count) 条 · 点一句就能播")
            .font(theme.typography.font(.sayMeta))
            .foregroundStyle(theme.colors.sayMetaText)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 2)
            .accessibilityIdentifier(AccessibilityID.phraseFooter)
    }
}