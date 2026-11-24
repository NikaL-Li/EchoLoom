import SwiftUI

@main
struct YizhenApp: App {
    #if DEBUG
    @State private var appState = YZAppState(
        sessionStore: YZMemorySessionStore(sessions: YZSampleData.sessions),
        phraseStore: YZMemoryPhraseStore(phrases: YZSampleData.phrases)
    )
    #else
    @State private var appState = YZAppState()
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}