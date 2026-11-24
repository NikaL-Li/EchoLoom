import SwiftUI

struct DockGlassContainer<Content: View>: View {
    let content: Content

    @Environment(\.yzTheme) private var theme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(theme.metrics.spacing.dockContainerPadding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.metrics.radius.dockContainer, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: theme.metrics.radius.dockContainer, style: .continuous)
                        .fill(theme.colors.dockGlassTint)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: theme.metrics.radius.dockContainer, style: .continuous)
                    .strokeBorder(theme.colors.separator, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radius.dockContainer, style: .continuous))
            .yzShadow(theme.colors.isDark ? theme.shadow.dockUp : theme.shadow.card)
    }
}