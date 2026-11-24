import SwiftUI

struct DialogTalkBar<SceneNav: View>: View {
    let onClose: () -> Void
    let onFaceToFace: () -> Void
    let sceneNav: SceneNav

    @Environment(\.yzTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            TalkBarToolRow(onClose: onClose, onFaceToFace: onFaceToFace)
            sceneNav
        }
        .padding(.horizontal, theme.metrics.spacing.pageHorizontal)
        .padding(.top, theme.metrics.spacing.talkBarTop)
        .padding(.bottom, theme.metrics.spacing.talkBarBottom)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(theme.colors.glassTint)
            }
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.colors.separator)
                .frame(height: 1)
        }
        .yzShadow(theme.shadow.talkBar)
        .zIndex(40)
        .accessibilityIdentifier(AccessibilityID.talkBar)
    }
}