import SwiftUI

struct DockLayer: View {
    let bannerVisible: Bool
    let bannerText: String
    var isInteractionEnabled: Bool = true
    var focusSpeakToken: Int = 0
    let onListen: () -> Void
    let onSpeak: () -> Void
    let onFullScreen: () -> Void

    @Environment(\.yzTheme) private var theme
    @AccessibilityFocusState private var speakFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if bannerVisible {
                EmergencyBanner(text: bannerText)
                    .padding(.bottom, theme.metrics.spacing.buttonGap)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            DockGlassContainer {
                HStack(spacing: theme.metrics.spacing.buttonGap) {
                    ActionButton(title: "听对方说", kind: .primary, action: onListen)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier(AccessibilityID.actionListen)

                    ActionButton(title: "我要说", kind: .secondary, action: onSpeak)
                        .frame(maxWidth: .infinity)
                        .accessibilityFocused($speakFocused)
                        .accessibilityIdentifier(AccessibilityID.actionSpeak)

                    ActionButton(title: "全屏", kind: .secondary, action: onFullScreen)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier(AccessibilityID.actionFullScreen)
                }
            }
        }
        .padding(.horizontal, theme.metrics.spacing.dockInset)
        .padding(.bottom, theme.metrics.spacing.dockInset)
        .frame(maxWidth: theme.metrics.size.dockMaxWidth)
        .frame(maxWidth: .infinity)
        .animation(theme.motion.bannerTransitionAnimation, value: bannerVisible)
        .zIndex(50)
        .allowsHitTesting(isInteractionEnabled)
        .accessibilityHidden(!isInteractionEnabled)
        .onChange(of: focusSpeakToken) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                speakFocused = true
            }
        }
        .accessibilityIdentifier(AccessibilityID.dock)
    }
}