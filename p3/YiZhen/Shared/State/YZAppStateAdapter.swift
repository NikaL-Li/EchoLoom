import Foundation

@MainActor
final class YZAppStateAdapter {
    private let appState: YZAppState

    init(appState: YZAppState) {
        self.appState = appState
    }

    var adaptedState: YZAppState {
        appState
    }

    func forwardSceneSelection(_ id: YZScene.ID) {
        appState.selectScene(id)
    }

    func forwardPhaseSelection(_ id: YZPhase.ID) {
        appState.selectPhase(id)
    }

    func forwardViewSelection(_ view: YZDialogView) {
        appState.selectView(view)
    }
}