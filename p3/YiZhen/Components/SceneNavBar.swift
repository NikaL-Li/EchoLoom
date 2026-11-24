import SwiftUI

struct SceneNavBar: View {
    let context: SceneNavContext

    var body: some View {
        PlaceholderSceneNavBar(context: context)
    }
}

struct PlaceholderSceneNavBar: View {
    let context: SceneNavContext

    @Environment(\.yzTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            SceneCapsuleRow(
                scenes: context.scenes,
                selectedSceneID: context.selectedSceneID,
                onSelect: context.onSelectScene
            )

            phaseNav
                .padding(.top, theme.metrics.spacing.subNavTop)
        }
    }

    @ViewBuilder
    private var phaseNav: some View {
        if context.phases.isEmpty {
            EmptyView()
        } else if context.navStyle == .step {
            PhaseStepNav(
                phases: context.phases,
                currentPhaseID: context.currentPhaseID,
                onSelectPhase: context.onSelectPhase
            )
        } else {
            PhaseTabNav(
                phases: context.phases,
                currentPhaseID: context.currentPhaseID,
                onSelectPhase: context.onSelectPhase
            )
        }
    }
}