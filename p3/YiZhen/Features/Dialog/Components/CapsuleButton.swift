import SwiftUI

struct CapsuleSpec {
    let title: String
    let font: Font
    let height: CGFloat
    let minWidth: CGFloat?
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let textColor: Color
    let fill: Color
    let stroke: Color?
    let shadow: YZShadowTokens.Entry
    let hitHeight: CGFloat
    let pressedFill: Color?
    let pressedText: Color?
    let pressedStroke: Color?
    let accessibilityLabel: String
    let accessibilityHint: String?
    let minimumScaleFactor: CGFloat
}

extension CapsuleSpec {
    static func close(_ theme: YZTheme) -> CapsuleSpec {
        CapsuleSpec(
            title: "关闭",
            font: theme.typography.font(.closeLabel),
            height: theme.metrics.size.closeHeight,
            minWidth: theme.metrics.size.closeMinWidth,
            cornerRadius: theme.metrics.radius.sceneCapsuleFull,
            horizontalPadding: theme.metrics.spacing.closePaddingH,
            textColor: theme.colors.closeLabel,
            fill: theme.colors.surface,
            stroke: nil,
            shadow: theme.shadow.closePill,
            hitHeight: theme.metrics.size.closeHeight,
            pressedFill: nil,
            pressedText: nil,
            pressedStroke: nil,
            accessibilityLabel: "关闭",
            accessibilityHint: "返回首页（本期为占位提示）",
            minimumScaleFactor: 0.9
        )
    }

    static func face(_ theme: YZTheme) -> CapsuleSpec {
        CapsuleSpec(
            title: "面对面",
            font: theme.typography.font(.facePill),
            height: theme.metrics.size.faceHeight,
            minWidth: nil,
            cornerRadius: theme.metrics.radius.facePill,
            horizontalPadding: theme.metrics.spacing.facePaddingH,
            textColor: theme.colors.textSecondary,
            fill: theme.colors.surface,
            stroke: theme.colors.separator,
            shadow: .none,
            hitHeight: theme.metrics.size.hitTarget,
            pressedFill: theme.colors.accentFill,
            pressedText: theme.colors.onAccent,
            pressedStroke: theme.colors.accentFill,
            accessibilityLabel: "面对面",
            accessibilityHint: "切换面对面模式（本期为占位提示）",
            minimumScaleFactor: 0.9
        )
    }
}

struct CapsuleButtonStyle: ButtonStyle {
    let spec: CapsuleSpec

    @Environment(\.yzTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let textColor = pressed ? (spec.pressedText ?? spec.textColor) : spec.textColor
        let fill = pressed ? (spec.pressedFill ?? spec.fill) : spec.fill
        let stroke = pressed ? (spec.pressedStroke ?? spec.stroke) : spec.stroke

        return Text(spec.title)
            .font(spec.font)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(spec.minimumScaleFactor)
            .padding(.horizontal, spec.horizontalPadding)
            .frame(minWidth: spec.minWidth, minHeight: spec.height)
            .background(
                RoundedRectangle(cornerRadius: spec.cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: spec.cornerRadius, style: .continuous)
                    .strokeBorder(stroke ?? Color.clear, lineWidth: stroke == nil ? 0 : 1)
            )
            .yzShadow(spec.shadow)
            .frame(minHeight: max(spec.height, spec.hitHeight))
            .contentShape(Rectangle())
            .scaleEffect(pressed ? theme.motion.pressScale : 1)
            .animation(theme.motion.pressAnimation, value: pressed)
    }
}

struct CapsuleButton: View {
    let spec: CapsuleSpec
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(CapsuleButtonStyle(spec: spec))
        .accessibilityLabel(Text(spec.accessibilityLabel))
        .accessibilityHint(Text(spec.accessibilityHint ?? ""))
    }
}

struct ClosePill: View {
    let action: () -> Void

    @Environment(\.yzTheme) private var theme

    var body: some View {
        CapsuleButton(spec: .close(theme), action: action)
            .accessibilityIdentifier(AccessibilityID.close)
    }
}

struct FacePill: View {
    let action: () -> Void

    @Environment(\.yzTheme) private var theme

    var body: some View {
        CapsuleButton(spec: .face(theme), action: action)
            .accessibilityIdentifier(AccessibilityID.faceToFace)
    }
}