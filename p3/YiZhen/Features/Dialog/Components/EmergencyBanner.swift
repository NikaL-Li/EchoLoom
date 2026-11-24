import SwiftUI

struct EmergencyBanner: View {
    let text: String

    @Environment(\.yzTheme) private var theme

    var body: some View {
        Text(text)
            .font(theme.typography.font(.bannerLabel))
            .foregroundStyle(theme.colors.bannerText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, theme.metrics.spacing.cardPadding)
            .frame(maxWidth: .infinity, minHeight: theme.metrics.size.bannerMinHeight)
            .background(
                RoundedRectangle(cornerRadius: theme.metrics.radius.button, style: .continuous)
                    .fill(theme.colors.bannerBg)
            )
            .yzShadow(theme.shadow.banner)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(text))
            .accessibilityAddTraits(.isStaticText)
            .accessibilityIdentifier(AccessibilityID.emergencyBanner)
    }
}