import SwiftUI

struct ContentComposition<Dialogue: View, Phrases: View>: View {
    let selectedView: YZDialogView
    let onSelectView: (YZDialogView) -> Void
    let reserve: CGFloat
    let dialogue: Dialogue
    let phrases: Phrases

    @Environment(\.yzTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            ViewSegmentControl(selectedView: selectedView, onSelect: onSelectView)
                .padding(.top, theme.metrics.spacing.phaseSegmentGap)

            ZStack {
                dialogue
                    .contentMargins(.bottom, reserve, for: .scrollContent)
                    .opacity(selectedView == .dialog ? 1 : 0)
                    .allowsHitTesting(selectedView == .dialog)
                    .accessibilityHidden(selectedView != .dialog)

                phrases
                    .contentMargins(.bottom, reserve, for: .scrollContent)
                    .opacity(selectedView == .phrases ? 1 : 0)
                    .allowsHitTesting(selectedView == .phrases)
                    .accessibilityHidden(selectedView != .phrases)
            }
            .padding(.top, theme.metrics.spacing.segmentContentGap)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .padding(.horizontal, theme.metrics.spacing.pageHorizontal)
        .frame(maxWidth: theme.metrics.size.maxContentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}