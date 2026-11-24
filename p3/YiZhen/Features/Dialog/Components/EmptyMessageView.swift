import SwiftUI

struct EmptyMessageView: View {
    @Environment(\.yzTheme) private var theme

    var body: some View {
        VStack(spacing: theme.metrics.spacing.cardGap) {
            RoundedRectangle(cornerRadius: theme.metrics.radius.iconTile, style: .continuous)
                .fill(theme.colors.accentSoft)
                .frame(width: theme.metrics.size.iconTile, height: theme.metrics.size.iconTile)
                .overlay(
                    Image(systemName: "ear")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.colors.accent)
                )
                .accessibilityHidden(true)

            Text("把手机放在桌上，点下面开始")
                .font(theme.typography.font(.body))
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("把手机放在桌上，点下面开始")
        .accessibilityIdentifier(AccessibilityID.empty)
    }
}