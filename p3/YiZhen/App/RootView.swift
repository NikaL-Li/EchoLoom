import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dependencies: DialogDependencies
    @State private var appState: YZAppState

    @MainActor
    init(baseline: YZBaseline = .current) {
        let toastCenter = ToastCenter()
        let resolvedDependencies = DialogDependencies.placeholder(baseline: baseline, toastCenter: toastCenter)
        let phraseBaseline = YZPhraseBaseline.current
        _dependencies = State(initialValue: resolvedDependencies)
        _appState = State(
            initialValue: YZAppState(
                session: YZMockData.session(baseline: baseline, phraseBaseline: phraseBaseline),
                phraseBaseline: phraseBaseline
            )
        )
    }

    var body: some View {
        let theme = dependencies.themeProvider.theme(for: colorScheme, reduceMotion: reduceMotion)

        StaticDialogPage(
            dependencies: dependencies,
            sceneNav: { context in SceneNavBar(context: context) },
            phraseContent: { context in SayList(context: context) }
        )
        .environment(\.yzTheme, theme)
        .environment(appState)
    }
}