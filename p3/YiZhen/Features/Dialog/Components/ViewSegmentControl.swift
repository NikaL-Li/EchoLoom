import SwiftUI

struct ViewSegmentControl: View {
    let selectedView: YZDialogView
    let onSelect: (YZDialogView) -> Void

    @Environment(\.yzTheme) private var theme
    @ScaledMetric(relativeTo: .footnote) private var scaledThumbHeight: CGFloat = 28

    private var thumbHeight: CGFloat {
        max(theme.metrics.size.segmentThumbHeight, scaledThumbHeight)
    }

    private var containerHeight: CGFloat {
        thumbHeight + 4
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(YZDialogView.allCases, id: \.rawValue) { view in
                Button {
                    onSelect(view)
                } label: {
                    Text(view.title)
                        .font(theme.typography.font(.captionStrong))
                        .foregroundStyle(view == selectedView ? theme.colors.textPrimary : theme.colors.textWeak)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(minHeight: thumbHeight)
                        .background(
                            RoundedRectangle(cornerRadius: theme.metrics.radius.segmentThumb, style: .continuous)
                                .fill(view == selectedView ? theme.colors.surface : Color.clear)
                        )
                        .yzShadow(view == selectedView ? theme.shadow.segmentThumb : .none)
                        .frame(minHeight: max(theme.metrics.size.hitTarget, thumbHeight))
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressableButtonStyle())
                .accessibilityIdentifier(AccessibilityID.segment(view))
                .accessibilityLabel(Text(view.title))
                .accessibilityAddTraits(view == selectedView ? [.isButton, .isSelected] : [.isButton])
            }
        }
        .padding(.horizontal, 2)
        .background {
            RoundedRectangle(cornerRadius: theme.metrics.radius.segmentContainer, style: .continuous)
                .fill(theme.colors.separator)
                .frame(height: containerHeight)
        }
        .animation(theme.motion.segmentSwitchAnimation, value: selectedView)
    }
}