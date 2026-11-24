import SwiftUI

struct SceneChip: View {
    let scene: YZScene
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(SceneChipStyle(scene: scene, isSelected: isSelected))
        .accessibilityLabel(Text(scene.name))
        .accessibilityValue(Text(scene.isEmergency ? "紧急场景" : ""))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityIdentifier(AccessibilityID.scene(scene.id))
    }
}

struct SceneChipStyle: ButtonStyle {
    let scene: YZScene
    let isSelected: Bool

    @Environment(\.yzTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        let fill = isSelected ? theme.colors.chipSelectedBg : theme.colors.sceneChipIdle
        let textColor = isSelected ? theme.colors.chipSelectedText : theme.colors.textSecondary
        let weight: Font.Weight = isSelected ? .semibold : .medium

        return Text(scene.name)
            .font(theme.typography.font(for: .sceneChip, weight: weight))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, theme.metrics.spacing.chipPaddingH)
            .frame(minHeight: theme.metrics.size.sceneHeight)
            .background(Capsule().fill(fill))
            .frame(minHeight: theme.metrics.size.hitTarget)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? theme.motion.pressScale : 1)
            .animation(theme.motion.pressAnimation, value: configuration.isPressed)
    }
}