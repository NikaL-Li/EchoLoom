import SwiftUI

struct RecordingGlowSlot: View {
    let isActive: Bool
    let theme: YZTheme

    var body: some View {
        if isActive && theme.motion.recordingGlowEnabled {
            HStack(spacing: 0) {
                edge
                Spacer(minLength: 0)
                edge
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            Color.clear
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var edge: some View {
        Rectangle()
            .fill(theme.colors.accent)
            .frame(width: 3)
            .opacity(0.35)
    }
}