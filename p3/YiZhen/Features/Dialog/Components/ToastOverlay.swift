import SwiftUI

struct ToastOverlay: View {
    let toast: YZToast?

    @Environment(\.yzTheme) private var theme

    var body: some View {
        Group {
            if let toast {
                Text(toast.message)
                    .font(theme.typography.font(.body))
                    .foregroundStyle(theme.colors.toastText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: theme.metrics.radius.toast, style: .continuous)
                            .fill(theme.colors.toastSurface)
                    )
                    .yzShadow(theme.shadow.toast)
                    .transition(.opacity)
                    .accessibilityIdentifier(AccessibilityID.toast)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(theme.motion.toastAnimation, value: toast)
        .allowsHitTesting(false)
    }
}