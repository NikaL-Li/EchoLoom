import SwiftUI

enum ActionButtonKind: Equatable {
    case primary
    case secondary
}

struct ActionButton: View {
    let title: String
    let kind: ActionButtonKind
    let action: () -> Void

    @Environment(\.yzTheme) private var theme

    private var foreground: Color {
        switch kind {
        case .primary: return theme.colors.onAccent
        case .secondary: return theme.colors.accent
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return theme.colors.accentFill
        case .secondary: return theme.colors.surface
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.font(.dockButton))
                .foregroundStyle(foreground)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: theme.metrics.size.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.dockButton, style: .continuous)
                        .fill(background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.dockButton, style: .continuous)
                        .strokeBorder(
                            kind == .secondary ? theme.colors.secondaryButtonStroke : Color.clear,
                            lineWidth: kind == .secondary ? 1 : 0
                        )
                )
                .yzShadow(kind == .primary ? theme.shadow.dockPrimary : .none)
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())
        .accessibilityLabel(Text(title))
    }
}