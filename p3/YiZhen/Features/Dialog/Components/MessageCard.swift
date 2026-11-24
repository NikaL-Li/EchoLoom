import SwiftUI

struct MessageCard: View {
    let message: YZMessage
    let sceneID: YZScene.ID
    let onReplay: () -> Void
    let onCopy: () -> Void
    let onOpenCard: () -> Void

    @Environment(\.yzTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            subject

            bottomRow
        }
        .padding(.top, theme.metrics.spacing.cardPadding)
        .padding(.bottom, theme.metrics.spacing.cardPadding)
        .padding(.leading, message.direction == .mine ? 12 : theme.metrics.spacing.cardPadding)
        .padding(.trailing, theme.metrics.spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous)
                .fill(theme.colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous)
                .strokeBorder(theme.colors.separator, lineWidth: theme.metrics.size.cardStroke)
        )
        .overlay(alignment: message.direction == .mine ? .leading : .trailing) {
            Rectangle()
                .fill(message.direction == .mine ? theme.colors.accentFill : theme.colors.success)
                .frame(width: theme.metrics.size.edgeBarWidth)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous))
        .yzShadow(theme.shadow.card)
    }

    private var subject: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacing.cardLabelGap) {
            if message.direction == .other {
                Text(YZFormatting.cardLabel(sceneID: sceneID, date: message.createdAt))
                    .font(theme.typography.font(.cardLabel))
                    .foregroundStyle(theme.colors.cardLabelText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Text(message.text)
                .font(theme.typography.font(.cardSentence))
                .foregroundStyle(theme.colors.textPrimary)
                .lineSpacing(theme.typography.lineSpacing(for: .cardSentence))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, theme.metrics.spacing.cardFootTop)
        .frame(maxWidth: .infinity, minHeight: theme.metrics.size.hitTarget, alignment: .topLeading)
        .contentShape(Rectangle())
        .yzCardPress()
        .onTapGesture(perform: onOpenCard)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(YZFormatting.cardAccessibilityLabel(message, sceneID: sceneID)))
        .accessibilityHint(Text("全屏大字牌筹备中"))
        .accessibilityIdentifier(AccessibilityID.message(message.id))
    }

    @ViewBuilder
    private var bottomRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: theme.metrics.spacing.buttonGap) {
                if message.direction == .mine {
                    leftArea
                }
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    actionRow
                }
            }
            .frame(minHeight: 24)
        } else {
            HStack(spacing: 0) {
                leftArea
                actionRow
            }
            .frame(minHeight: 24)
        }
    }

    private var leftArea: some View {
        HStack(spacing: 0) {
            if message.direction == .mine {
                StatusPill(kind: message.statusKind, text: message.statusText)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: theme.metrics.size.hitTarget, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenCard)
        .accessibilityHidden(true)
    }

    private var actionRow: some View {
        MessageCardActionRow(
            messageID: message.id,
            onReplay: onReplay,
            onCopy: onCopy
        )
    }
}