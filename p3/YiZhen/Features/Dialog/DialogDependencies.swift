import SwiftUI

struct SceneNavContext {
    let scenes: [YZScene]
    let phases: [YZPhase]
    let selectedSceneID: YZScene.ID
    let currentPhaseID: YZPhase.ID?
    let onSelectScene: (YZScene.ID) -> Void
    let navStyle: YZNavStyle
    let onSelectPhase: ((YZPhase.ID) -> Void)?

    init(
        scenes: [YZScene],
        phases: [YZPhase],
        selectedSceneID: YZScene.ID,
        currentPhaseID: YZPhase.ID?,
        onSelectScene: @escaping (YZScene.ID) -> Void,
        navStyle: YZNavStyle = .step,
        onSelectPhase: ((YZPhase.ID) -> Void)? = nil
    ) {
        self.scenes = scenes
        self.phases = phases
        self.selectedSceneID = selectedSceneID
        self.currentPhaseID = currentPhaseID
        self.onSelectScene = onSelectScene
        self.navStyle = navStyle
        self.onSelectPhase = onSelectPhase
    }
}

struct SayListContext {
    let phrases: [YZPhrase]
    let phaseName: String
    let emptyText: String
    let onUse: (YZPhrase.ID) -> Void

    init(
        phrases: [YZPhrase],
        phaseName: String = "",
        emptyText: String = "这个场景还没有句子",
        onUse: @escaping (YZPhrase.ID) -> Void
    ) {
        self.phrases = phrases
        self.phaseName = phaseName
        self.emptyText = emptyText
        self.onUse = onUse
    }
}

@MainActor
struct DialogDependencies {
    let themeProvider: any YZThemeProviding
    let toastCenter: ToastCenter
    let dialogActions: any DialogActionHandling
    let messageActions: any MessageActionHandling
    let baseline: YZBaseline

    static func placeholder(baseline: YZBaseline = .current) -> DialogDependencies {
        placeholder(baseline: baseline, toastCenter: ToastCenter())
    }

    static func placeholder(baseline: YZBaseline, toastCenter: ToastCenter) -> DialogDependencies {
        DialogDependencies(
            themeProvider: YZPlaceholderThemeProvider(),
            toastCenter: toastCenter,
            dialogActions: PlaceholderDialogActionHandler(toast: toastCenter),
            messageActions: PlaceholderMessageActionHandler(toast: toastCenter),
            baseline: baseline
        )
    }
}