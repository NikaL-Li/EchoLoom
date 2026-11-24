import SwiftUI

struct PhaseTabNav: View {
    let phases: [YZPhase]
    let currentPhaseID: YZPhase.ID?
    let onSelectPhase: ((YZPhase.ID) -> Void)?

    @Environment(\.yzTheme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.metrics.spacing.tabItemGap) {
                ForEach(phases) { phase in
                    item(phase)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.colors.separator)
                    .frame(height: 1)
            }
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func item(_ phase: YZPhase) -> some View {
        let isCurrent = phase.id == currentPhaseID
        let content = VStack(spacing: 0) {
            Text(phase.name)
                .font(theme.typography.font(for: .phaseTabLabel, weight: isCurrent ? .semibold : .medium))
                .foregroundStyle(isCurrent ? theme.colors.accent : theme.colors.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 2)
                .padding(.top, 10)
                .padding(.bottom, 10)
            Rectangle()
                .fill(isCurrent ? theme.colors.accent : Color.clear)
                .frame(height: theme.metrics.size.tabIndicator)
        }
        .frame(minHeight: theme.metrics.size.hitTarget)
        .contentShape(Rectangle())

        if let selectPhase = onSelectPhase {
            Button {
                selectPhase(phase.id)
            } label: {
                content
            }
            .buttonStyle(YZPressableButtonStyle())
            .accessibilityLabel(Text(phase.name))
            .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : [.isButton])
            .accessibilityIdentifier(AccessibilityID.phase(phase.id))
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(phase.name))
                .accessibilityAddTraits(.isStaticText)
                .accessibilityIdentifier(AccessibilityID.phase(phase.id))
        }
    }
}