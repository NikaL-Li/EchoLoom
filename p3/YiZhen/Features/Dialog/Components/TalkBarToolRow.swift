import SwiftUI

struct TalkBarToolRow: View {
    let onClose: () -> Void
    let onFaceToFace: () -> Void

    @Environment(\.yzTheme) private var theme

    var body: some View {
        HStack(spacing: theme.metrics.spacing.sceneGap) {
            ClosePill(action: onClose)
            Text("译诊")
                .font(theme.typography.font(for: .navTitle, maxSize: 20))
                .foregroundStyle(theme.colors.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .accessibilityIdentifier(AccessibilityID.title)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: theme.metrics.spacing.sceneGap)
            FacePill(action: onFaceToFace)
        }
        .frame(minHeight: theme.metrics.size.closeHeight)
    }
}