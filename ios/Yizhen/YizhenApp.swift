import SwiftUI

@main
struct YizhenApp: App {
    @State private var appState: YZAppState

    @MainActor
    init() {
        let state = YZAppState()
        YZThemeRuntime.fontSize = state.fontSize.points
        YZThemeRuntime.highContrast = state.highContrast
        _appState = State(initialValue: state)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
