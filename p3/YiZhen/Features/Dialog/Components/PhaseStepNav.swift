import SwiftUI

struct PhaseStepNav: View {
    let phases: [YZPhase]
    let currentPhaseID: YZPhase.ID?
    let onSelectPhase: ((YZPhase.ID) -> Void)?

    @Environment(\.yzTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentIndex: Int? {
        phases.firstIndex { $0.id == currentPhaseID }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(phases.indices), id: \.self) { index in
                        item(index)
                            .id(phases[index].id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .padding(.vertical, theme.metrics.spacing.stepperVertical)
            .onAppear {
                scrollToCurrent(proxy, animated: false)
            }
            .onChange(of: currentPhaseID) { _, _ in
                scrollToCurrent(proxy, animated: !reduceMotion)
            }
        }
    }

    @ViewBuilder
    private func item(_ index: Int) -> some View {
        let phase = phases[index]
        let state = PhaseStepStateResolver.state(index: index, currentIndex: currentIndex)
        let content = itemContent(phase, index: index, state: state)

        if let selectPhase = onSelectPhase {
            Button {
                selectPhase(phase.id)
            } label: {
                content
            }
            .buttonStyle(YZPressableButtonStyle())
            .accessibilityLabel(Text(phase.name))
            .accessibilityValue(Text(state.accessibilityValue))
            .accessibilityAddTraits(state == .current ? [.isButton, .isSelected] : [.isButton])
            .accessibilityIdentifier(AccessibilityID.phase(phase.id))
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(phase.name))
                .accessibilityValue(Text(state.accessibilityValue))
                .accessibilityAddTraits(.isStaticText)
                .accessibilityIdentifier(AccessibilityID.phase(phase.id))
        }
    }

    private func itemContent(_ phase: YZPhase, index: Int, state: PhaseStepState) -> some View {
        VStack(spacing: theme.metrics.size.stepperDotLabelGap) {
            dot(index: index, state: state)
            Text(phase.name)
                .font(theme.typography.font(for: .phaseStepLabel, weight: state == .current ? .semibold : .medium))
                .foregroundStyle(labelColor(for: state))
                .lineLimit(1)
        }
        .frame(minWidth: theme.metrics.size.stepperItemMinWidth)
        .background(alignment: .top) {
            if let lineColor = PhaseStepStateResolver.lineColor(index: index, currentIndex: currentIndex, colors: theme.colors) {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let start = index == 0 ? width / 2 : 0
                    let end = index == phases.count - 1 ? width / 2 : width
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: max(0, end - start), height: theme.metrics.size.stepperLine)
                        .position(
                            x: (start + end) / 2,
                            y: theme.metrics.size.stepperDot / 2
                        )
                }
            }
        }
        .frame(minHeight: theme.metrics.size.hitTarget)
        .contentShape(Rectangle())
    }

    private func dot(index: Int, state: PhaseStepState) -> some View {
        let background: Color = {
            switch state {
            case .done: return theme.colors.accentSoft
            case .current: return theme.colors.accentFill
            case .upcoming: return theme.colors.stepIdle
            }
        }()
        let numberColor: Color = {
            switch state {
            case .done: return theme.colors.accent
            case .current: return theme.colors.onAccent
            case .upcoming: return theme.colors.textWeak
            }
        }()

        return ZStack {
            Circle()
                .fill(background)
                .frame(width: theme.metrics.size.stepperDot, height: theme.metrics.size.stepperDot)
            Text("\(index + 1)")
                .font(theme.typography.font(.phaseStepNumber))
                .foregroundStyle(numberColor)
        }
        .background {
            if state == .current {
                Circle()
                    .fill(theme.colors.accentSoft)
                    .frame(
                        width: theme.metrics.size.stepperDot + 8,
                        height: theme.metrics.size.stepperDot + 8
                    )
            }
        }
    }

    private func labelColor(for state: PhaseStepState) -> Color {
        switch state {
        case .done, .current: return theme.colors.accent
        case .upcoming: return theme.colors.textWeak
        }
    }

    private func scrollToCurrent(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let phaseID = currentPhaseID else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.18)) {
                proxy.scrollTo(phaseID, anchor: .center)
            }
        } else {
            proxy.scrollTo(phaseID, anchor: .center)
        }
    }
}