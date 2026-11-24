import SwiftUI

@main
struct YizhenApp: App {
    @State private var appState: YZAppState

    init() {
        #if DEBUG
        let store = YZFeatureSessionStore()
        let state = YZAppState(
            sessionStore: store,
            phraseStore: YZMemoryPhraseStore(phrases: YZSampleData.phrases)
        )
        if state.sessions.isEmpty {
            state.sessions = YZSampleData.sessions
        }
        #else
        let state = YZAppState(sessionStore: YZFeatureSessionStore())
        #endif

        YZProfileSettingsPersistence.load(into: state)
        YZThemeRuntime.fontSize = CGFloat(state.fontSize.rawValue)
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