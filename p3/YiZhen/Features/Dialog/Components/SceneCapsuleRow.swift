import SwiftUI

struct SceneCapsuleRow: View {
    let scenes: [YZScene]
    let selectedSceneID: YZScene.ID
    let onSelect: (YZScene.ID) -> Void

    @Environment(\.yzTheme) private var theme

    var body: some View {
        Group {
            if scenes.isEmpty {
                Text("暂无场景")
                    .font(theme.typography.font(.caption))
                    .foregroundStyle(theme.colors.textWeak)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.metrics.spacing.sceneGap) {
                        ForEach(scenes) { scene in
                            SceneChip(
                                scene: scene,
                                isSelected: scene.id == selectedSceneID,
                                action: { onSelect(scene.id) }
                            )
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.metrics.spacing.chipsTop)
    }
}