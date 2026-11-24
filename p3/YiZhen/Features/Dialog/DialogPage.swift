import SwiftUI

struct DialogPage<SceneNav: View, PhraseContent: View>: View {
    let dependencies: DialogDependencies
    let sceneNav: (SceneNavContext) -> SceneNav
    let phraseContent: (SayListContext) -> PhraseContent

    @Environment(\.yzTheme) private var theme
    @Environment(YZAppState.self) private var appState
    @State private var viewModel: DialogViewModel
    @State private var keyboardObserver = KeyboardHeightObserver()
    @State private var composerHeight: CGFloat = 0
    @State private var speakFocusToken = 0
    @ScaledMetric(relativeTo: .body) private var scaledDockReserve: CGFloat = 82
    @ScaledMetric(relativeTo: .body) private var scaledEmergencyReserve: CGFloat = 138

    init(
        dependencies: DialogDependencies,
        sceneNav: @escaping (SceneNavContext) -> SceneNav,
        phraseContent: @escaping (SayListContext) -> PhraseContent,
        composerInitiallyPresented: Bool = false,
        composerInitialDraft: String = ""
    ) {
        self.dependencies = dependencies
        self.sceneNav = sceneNav
        self.phraseContent = phraseContent
        _viewModel = State(
            initialValue: DialogViewModel(
                isComposerPresented: composerInitiallyPresented,
                draft: composerInitialDraft
            )
        )
    }

    var body: some View {
        let banner = appState.emergencyBanner
        let toast = dependencies.toastCenter.current
        let composerOpen = viewModel.isComposerPresented
        let keyboardHeight = keyboardObserver.height
        let baseReserve = banner.visible
            ? max(theme.metrics.size.contentBottomReserveEmergency, scaledEmergencyReserve)
            : max(theme.metrics.size.contentBottomReserve, scaledDockReserve)
        let reserve = composerOpen
            ? max(baseReserve, keyboardHeight + composerHeight + theme.metrics.spacing.cardGap)
            : baseReserve
        let toastBottom = composerOpen
            ? keyboardHeight + composerHeight + theme.metrics.spacing.cardGap
            : baseReserve + theme.metrics.spacing.cardGap

        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                DialogTalkBar(
                    onClose: { dependencies.dialogActions.close() },
                    onFaceToFace: { dependencies.dialogActions.faceToFace() },
                    sceneNav: sceneNav(sceneNavContext)
                )

                ContentComposition(
                    selectedView: appState.selectedView,
                    onSelectView: { appState.selectView($0) },
                    reserve: reserve,
                    dialogue: MessageListView(
                        messages: appState.messages,
                        sceneID: appState.selectedSceneID,
                        revealedIDs: viewModel.revealedMessageIDs,
                        onReveal: { viewModel.reveal($0) },
                        onReplay: { dependencies.messageActions.replay($0) },
                        onCopy: { dependencies.messageActions.copy($0) },
                        onOpenCard: { dependencies.messageActions.openCard($0) },
                        scrollTargetID: viewModel.pendingScrollMessageID,
                        onScrollConsumed: { viewModel.consumePendingScroll() }
                    ),
                    phrases: phraseContent(sayListContext)
                )
                .animation(theme.motion.bannerTransitionAnimation, value: banner.visible)
            }
        }
        .overlay(alignment: .bottom) {
            DockLayer(
                bannerVisible: banner.visible,
                bannerText: banner.text,
                isInteractionEnabled: !composerOpen,
                focusSpeakToken: speakFocusToken,
                onListen: { dependencies.dialogActions.listen() },
                onSpeak: { viewModel.openComposer() },
                onFullScreen: { dependencies.dialogActions.fullScreen() }
            )
        }
        .overlay {
            composerLayer
        }
        .overlay(alignment: .bottom) {
            ToastOverlay(toast: toast)
                .padding(.bottom, toastBottom)
                .allowsHitTesting(false)
                .zIndex(200)
        }
        .overlay {
            RecordingGlowSlot(isActive: false, theme: theme)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onDisappear {
            dependencies.toastCenter.cancel()
        }
    }

    @ViewBuilder
    private var composerLayer: some View {
        if viewModel.isComposerPresented {
            GeometryReader { proxy in
                let maxHeight = min(
                    proxy.size.height * theme.metrics.size.sheetMaxHeightRatio,
                    proxy.size.height - keyboardObserver.height - theme.metrics.size.sheetTopInset
                )

                ZStack(alignment: .bottom) {
                    theme.colors.scrim
                        .ignoresSafeArea()
                        .onTapGesture(perform: closeComposer)
                        .accessibilityHidden(true)
                        .zIndex(70)

                    ComposerDrawer(
                        draft: Binding(
                            get: { viewModel.draft },
                            set: { viewModel.draft = $0 }
                        ),
                        canSend: viewModel.canSend,
                        onSend: { _ = viewModel.submit(state: appState) },
                        onClose: closeComposer
                    )
                    .frame(maxWidth: theme.metrics.size.maxContentWidth)
                    .frame(maxHeight: max(0, maxHeight))
                    .composerHeightPreference()
                    .padding(.bottom, keyboardObserver.height)
                    .zIndex(80)
                }
                .onPreferenceChange(ComposerHeightPreferenceKey.self) { height in
                    composerHeight = height
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(theme.motion.composerAnimation, value: viewModel.isComposerPresented)
        }
    }

    private func closeComposer() {
        viewModel.closeComposer()
        speakFocusToken += 1
    }

    private var sceneNavContext: SceneNavContext {
        SceneNavContext(
            scenes: appState.scenes,
            phases: appState.phases,
            selectedSceneID: appState.selectedSceneID,
            currentPhaseID: appState.selectedPhaseID,
            onSelectScene: { appState.selectScene($0) },
            navStyle: appState.navStyle(of: appState.selectedSceneID),
            onSelectPhase: { appState.selectPhase($0) }
        )
    }

    private var sayListContext: SayListContext {
        SayListContext(
            phrases: appState.phrases,
            phaseName: appState.selectedPhase?.name ?? "",
            emptyText: "这个场景还没有句子",
            onUse: { _ in
                dependencies.toastCenter.show(YZToast(id: "phrase.use", message: "播报功能筹备中"))
            }
        )
    }
}

typealias StaticDialogPage = DialogPage<SceneNavBar, SayList>