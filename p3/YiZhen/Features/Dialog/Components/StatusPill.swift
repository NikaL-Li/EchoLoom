import SwiftUI

struct StatusPill: View {
    let kind: YZStatusKind
    let text: String

    @Environment(\.yzTheme) private var theme

    private var foreground: Color {
        switch kind {
        case .plain: return theme.colors.pillPlainText
        case .ok: return theme.colors.pillOkText
        case .fail: return theme.colors.pillFailText
        }
    }

    private var background: Color {
        switch kind {
        case .plain: return theme.colors.pillPlainBg
        case .ok: return theme.colors.pillOkBg
        case .fail: return theme.colors.pillFailBg
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(foreground)
                .frame(width: theme.metrics.size.pillDot, height: theme.metrics.size.pillDot)
            Text(text)
                .font(theme.typography.font(.statusPill))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, theme.metrics.spacing.pillPaddingH)
        .padding(.vertical, theme.metrics.spacing.pillPaddingV)
        .background(Capsule().fill(background))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(text))
    }
}