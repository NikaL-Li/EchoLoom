import SwiftUI

struct MessageCardActionRow: View {
    let messageID: YZMessage.ID
    let onReplay: () -> Void
    let onCopy: () -> Void

    @Environment(\.yzTheme) private var theme

    private let visualGap: CGFloat = 2

    var body: some View {
        HStack(spacing: 0) {
            actionButton(
                title: "重播",
                isTrailing: true,
                identifier: AccessibilityID.replay(messageID),
                action: onReplay
            )
            actionButton(
                title: "复制",
                isTrailing: false,
                identifier: AccessibilityID.copy(messageID),
                action: onCopy
            )
        }
    }

    private func actionButton(
        title: String,
        isTrailing: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.font(.cardAction))
                .foregroundStyle(theme.colors.cardActionText)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .frame(height: theme.metrics.size.cardActionHeight)
                .padding(isTrailing ? .trailing : .leading, visualGap / 2)
                .fixedSize(horizontal: true, vertical: false)
                .frame(
                    minWidth: theme.metrics.size.hitTarget,
                    minHeight: theme.metrics.size.hitTarget,
                    alignment: isTrailing ? .trailing : .leading
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())
        .accessibilityLabel(Text(title))
        .accessibilityIdentifier(identifier)
    }
}