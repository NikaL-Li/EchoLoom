import SwiftUI
import UIKit
import Foundation

struct TalkView<SceneNav: View, PhraseContent: View>: View {
    let textOnly: Bool
    let sceneNav: (SceneNavContext) -> SceneNav
    let phraseContent: (SayListContext) -> PhraseContent
    let onClose: () -> Void

    @Environment(\.yzTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(YZAppState.self) private var appState

    @State private var viewModel = DialogViewModel()
    @State private var keyboardObserver = KeyboardHeightObserver()
    @State private var toastCenter = ToastCenter()
    @State private var speechService = SpeechService()
    @State private var speechPlayer = SpeechPlayer()
    @State private var composerHeight: CGFloat = 0
    @State private var showFaceToFace = false
    @State private var signPresentation: SignPresentation?
    @State private var summaryItems: [String] = []
    @State private var isSummaryVisible = false
    @State private var revealedIDs: Set<YZMessage.ID> = []
    @State private var scrollTargetID: YZMessage.ID?
    @State private var lastFinalizedID: UUID?
    @State private var lastAppendedSpeechText = ""
    @ScaledMetric(relativeTo: .body) private var scaledDockReserve: CGFloat = 82
    @ScaledMetric(relativeTo: .body) private var scaledEmergencyReserve: CGFloat = 138

    init(
        textOnly: Bool = false,
        sceneNav: @escaping (SceneNavContext) -> SceneNav,
        phraseContent: @escaping (SayListContext) -> PhraseContent,
        onClose: @escaping () -> Void
    ) {
        self.textOnly = textOnly
        self.sceneNav = sceneNav
        self.phraseContent = phraseContent
        self.onClose = onClose
    }

    var body: some View {
        let banner = appState.emergencyBanner
        let composerOpen = viewModel.isComposerPresented
        let baseReserve = banner.visible
            ? max(theme.metrics.size.contentBottomReserveEmergency, scaledEmergencyReserve)
            : max(theme.metrics.size.contentBottomReserve, scaledDockReserve)
        let reserve = composerOpen
            ? max(baseReserve, keyboardObserver.height + composerHeight + theme.metrics.spacing.cardGap)
            : baseReserve
        let toastBottom = composerOpen
            ? keyboardObserver.height + composerHeight + theme.metrics.spacing.cardGap
            : baseReserve + theme.metrics.spacing.cardGap

        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                talkHeader

                if let notice = listenNotice {
                    TalkListenNotice(
                        kind: notice.kind,
                        message: notice.message,
                        onClose: notice.dismissible ? { speechService.clearError() } : nil
                    )
                    .padding(.horizontal, theme.metrics.spacing.pageHorizontal)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if showFaceToFace {
                    FaceView(
                        messages: appState.messages,
                        sceneID: appState.selectedSceneID,
                        onReplay: handleReplay,
                        onCopy: handleCopy,
                        onOpenCard: { openSign($0.text, tone: .plain) },
                        isScrollLocked: composerOpen
                    )
                    .padding(.horizontal, theme.metrics.spacing.pageHorizontal)
                    .padding(.top, 4)
                } else {
                    segmentedContent(reserve: reserve)
                }
            }
        }
        .overlay(alignment: .bottom) {
            dockLayer(bannerVisible: banner.visible, bannerText: banner.text, composerOpen: composerOpen)
        }
        .overlay {
            composerLayer
        }
        .overlay(alignment: .bottom) {
            ToastOverlay(toast: toastCenter.current)
                .padding(.bottom, toastBottom)
                .allowsHitTesting(false)
                .zIndex(200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(item: $signPresentation) { presentation in
            SignView(
                text: presentation.text,
                tone: presentation.tone,
                onDismiss: { signPresentation = nil }
            )
        }
        .onAppear {
            revealedIDs = Set(appState.messages.map(\.id))
        }
        .onDisappear {
            stopAudio()
            toastCenter.cancel()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            stopAudio()
        }
        .onChange(of: speechService.lastFinalized?.id) { _, newValue in
            guard let newValue, newValue != lastFinalizedID else { return }
            lastFinalizedID = newValue
            guard let finalized = speechService.lastFinalized else { return }
            appendOtherMessage(finalized.text)
        }
        .onChange(of: speechService.state) { _, newState in
            if newState == .blocked || newState == .failed {
                UIAccessibility.post(notification: .announcement, argument: speechService.errorMessage ?? "")
            }
        }
        .onChange(of: speechPlayer.lastResult?.id) { _, _ in
            handlePlaybackResult()
        }
        .onChange(of: appState.selectedSceneID) { _, _ in
            stopAudio()
            summaryItems = []
            isSummaryVisible = false
            scrollTargetID = appState.messages.last?.id
        }
        .onChange(of: appState.selectedPhaseID) { _, _ in
            stopAudio()
        }
    }

    private var talkHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.metrics.spacing.sceneGap) {
                ClosePill(action: closeTalk)

                Text("译诊")
                    .font(theme.typography.font(for: .navTitle, maxSize: 20))
                    .foregroundStyle(theme.colors.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .accessibilityIdentifier(AccessibilityID.title)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: theme.metrics.spacing.sceneGap)

                faceToFaceButton
            }
            .frame(minHeight: theme.metrics.size.closeHeight)

            sceneNav(sceneNavContext)
        }
        .padding(.horizontal, theme.metrics.spacing.pageHorizontal)
        .padding(.top, theme.metrics.spacing.talkBarTop)
        .padding(.bottom, theme.metrics.spacing.talkBarBottom)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(theme.colors.glassTint)
            }
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.colors.separator)
                .frame(height: 1)
        }
        .yzShadow(theme.shadow.talkBar)
        .zIndex(40)
    }

    private var faceToFaceButton: some View {
        Button(action: toggleFaceToFace) {
            Text("面对面")
                .font(theme.typography.font(for: .facePill))
                .foregroundStyle(showFaceToFace ? theme.colors.onAccent : theme.colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.horizontal, theme.metrics.spacing.facePaddingH)
                .frame(minHeight: theme.metrics.size.faceHeight)
                .background(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.facePill, style: .continuous)
                        .fill(showFaceToFace ? theme.colors.accentFill : theme.colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.facePill, style: .continuous)
                        .strokeBorder(
                            showFaceToFace ? Color.clear : theme.colors.separator,
                            lineWidth: showFaceToFace ? 0 : 1
                        )
                )
                .frame(minHeight: theme.metrics.size.hitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())
        .accessibilityLabel(Text("面对面"))
        .accessibilityValue(Text(showFaceToFace ? "已开启" : "已关闭"))
        .accessibilityHint(Text("切换面对面分屏"))
        .accessibilityIdentifier(AccessibilityID.faceToFace)
    }

    private func segmentedContent(reserve: CGFloat) -> some View {
        VStack(spacing: 0) {
            ViewSegmentControl(
                selectedView: appState.selectedView,
                onSelect: { appState.selectView($0) }
            )
            .padding(.top, theme.metrics.spacing.phaseSegmentGap)

            ZStack {
                dialogueContent(reserve: reserve)
                    .opacity(appState.selectedView == .dialog ? 1 : 0)
                    .allowsHitTesting(appState.selectedView == .dialog)
                    .accessibilityHidden(appState.selectedView != .dialog)

                phraseContent(sayListContext)
                    .contentMargins(.bottom, reserve, for: .scrollContent)
                    .opacity(appState.selectedView == .phrases ? 1 : 0)
                    .allowsHitTesting(appState.selectedView == .phrases)
                    .accessibilityHidden(appState.selectedView != .phrases)
            }
            .padding(.top, theme.metrics.spacing.segmentContentGap)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, theme.metrics.spacing.pageHorizontal)
        .frame(maxWidth: theme.metrics.size.maxContentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(theme.motion.bannerTransitionAnimation, value: appState.emergencyBanner.visible)
    }

    private func dialogueContent(reserve: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                summaryButton
            }
            .padding(.bottom, 8)

            if isSummaryVisible, !summaryItems.isEmpty {
                SummaryCard(items: summaryItems, onCopy: copySummary)
                    .padding(.bottom, 8)
            }

            conversation(reserve: reserve)
        }
    }

    private var summaryButton: some View {
        Button(action: generateSummary) {
            HStack(spacing: 6) {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 12, weight: .semibold))
                Text("生成要点")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(theme.colors.accent)
            .padding(.horizontal, 12)
            .frame(minHeight: 32)
            .background(Capsule().fill(theme.colors.accentSoft))
            .overlay(Capsule().strokeBorder(theme.colors.accentStroke, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())
        .accessibilityLabel(Text("生成要点"))
        .accessibilityIdentifier("featuretalk.summary.generate")
    }

    @ViewBuilder
    private func conversation(reserve: CGFloat) -> some View {
        if appState.messages.isEmpty && speechService.partialText.isEmpty {
            EmptyMessageView()
                .padding(.bottom, reserve)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: theme.metrics.spacing.cardGap) {
                        ForEach(appState.messages) { message in
                            MessageCard(
                                message: message,
                                sceneID: appState.selectedSceneID,
                                onReplay: { handleReplay(message) },
                                onCopy: { handleCopy(message) },
                                onOpenCard: { openSign(message.text, tone: .plain) }
                            )
                            .id(message.id)
                            .yzCardEntrance(isVisible: revealedIDs.contains(message.id))
                            .onAppear {
                                revealedIDs.insert(message.id)
                            }
                        }

                        if !speechService.partialText.isEmpty {
                            TalkInterimCard(text: speechService.partialText)
                                .id(interimID)
                        }
                    }
                    .padding(.vertical, theme.metrics.spacing.cardGap)
                }
                .contentMargins(.bottom, reserve, for: .scrollContent)
                .onAppear {
                    scrollToLatest(proxy, animated: false)
                }
                .onChange(of: appState.messages.last?.id) { _, _ in
                    scrollToLatest(proxy, animated: true)
                }
                .onChange(of: speechService.partialText) { _, _ in
                    scrollToLatest(proxy, animated: false)
                }
                .onChange(of: scrollTargetID) { _, target in
                    guard let target else { return }
                    proxy.scrollTo(target, anchor: .bottom)
                    scrollTargetID = nil
                }
            }
        }
    }

    private func dockLayer(bannerVisible: Bool, bannerText: String, composerOpen: Bool) -> some View {
        VStack(spacing: 0) {
            if bannerVisible {
                EmergencyBanner(text: bannerText)
                    .padding(.bottom, theme.metrics.spacing.buttonGap)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            DockGlassContainer {
                HStack(spacing: theme.metrics.spacing.buttonGap) {
                    TalkDockButton(
                        title: speechService.isActive ? "停止聆听" : "听对方说",
                        kind: .primary,
                        isEnabled: !speechService.isBlocked && !textOnly,
                        action: toggleListening
                    )
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(AccessibilityID.actionListen)
                    .accessibilityHint(
                        Text(
                            speechService.isBlocked
                                ? "麦克风未授权：语音识别已停用，请继续用文字输入。"
                                : ""
                        )
                    )

                    TalkDockButton(
                        title: "我要说",
                        kind: .secondary,
                        isEnabled: true,
                        action: openComposer
                    )
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(AccessibilityID.actionSpeak)

                    TalkDockButton(
                        title: "全屏",
                        kind: .secondary,
                        isEnabled: true,
                        action: showLatestSign
                    )
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(AccessibilityID.actionFullScreen)
                }
            }
        }
        .padding(.horizontal, theme.metrics.spacing.dockInset)
        .padding(.bottom, theme.metrics.spacing.dockInset)
        .frame(maxWidth: theme.metrics.size.dockMaxWidth)
        .frame(maxWidth: .infinity)
        .animation(theme.motion.bannerTransitionAnimation, value: bannerVisible)
        .zIndex(50)
        .allowsHitTesting(!composerOpen)
        .accessibilityHidden(composerOpen)
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
                        onSend: submitComposer,
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

    private var listenNotice: TalkListenNoticeContent? {
        switch speechService.state {
        case .requestingPermission, .listening:
            return TalkListenNoticeContent(kind: .listening, message: "正在听…", dismissible: false)
        case .reconnecting:
            return TalkListenNoticeContent(kind: .reconnecting, message: "正在重新连接…", dismissible: false)
        case .failed:
            return TalkListenNoticeContent(
                kind: .error,
                message: speechService.errorMessage ?? speechService.failureMessage,
                dismissible: true
            )
        case .blocked:
            return TalkListenNoticeContent(
                kind: .blocked,
                message: speechService.blockedMessage,
                dismissible: false
            )
        case .idle, .stopping:
            return nil
        }
    }

    private var sceneNavContext: SceneNavContext {
        SceneNavContext(
            scenes: appState.scenes,
            phases: appState.phases,
            selectedSceneID: appState.selectedSceneID,
            currentPhaseID: appState.selectedPhaseID,
            onSelectScene: { id in
                stopAudio()
                appState.selectScene(id)
            },
            navStyle: appState.navStyle(of: appState.selectedSceneID),
            onSelectPhase: { id in
                stopAudio()
                appState.selectPhase(id)
            }
        )
    }

    private var sayListContext: SayListContext {
        SayListContext(
            phrases: appState.phrases,
            phaseName: appState.selectedPhase?.name ?? "",
            emptyText: "这个场景还没有句子",
            onUse: { id in
                guard let phrase = appState.phrases.first(where: { $0.id == id }) else { return }
                if textOnly {
                    toastCenter.show(YZToast(id: "featuretalk.preset.textonly", message: "全程文字模式下不播报"))
                    return
                }
                speakNow(phrase.text, messageID: nil)
            }
        )
    }

    private func toggleFaceToFace() {
        withAnimation(theme.motion.bannerTransitionAnimation) {
            showFaceToFace.toggle()
        }
        if showFaceToFace {
            closeComposer()
        }
    }

    private func toggleListening() {
        if speechService.isActive {
            speechService.stop()
            return
        }
        guard !speechService.isBlocked, !textOnly else { return }
        speechPlayer.stop()
        lastAppendedSpeechText = ""
        speechService.start()
    }

    private func speakNow(_ text: String, messageID: String?) {
        if speechService.isActive {
            speechService.stop()
        }
        if let messageID {
            updateMessageStatus(messageID, status: "已播报")
        }
        speechPlayer.speak(text, messageID: messageID)
    }

    private func handlePlaybackResult() {
        guard let result = speechPlayer.lastResult else { return }
        if let messageID = result.messageID {
            updateMessageStatus(messageID, status: result.success ? "已播报" : "播报失败")
            if !result.success {
                UIAccessibility.post(notification: .announcement, argument: "播报失败，请用文字沟通")
            }
        } else if !result.success {
            toastCenter.show(
                YZToast(id: "featuretalk.preset.fail", message: "播报失败，请继续用文字输入。")
            )
        }
    }

    private func handleReplay(_ message: YZMessage) {
        guard message.direction == .mine else {
            openSign(message.text, tone: .plain)
            return
        }
        guard !textOnly else {
            updateMessageStatus(message.id, status: "文字直达")
            return
        }
        speakNow(message.text, messageID: message.id)
    }

    private func handleCopy(_ message: YZMessage) {
        toastCenter.show(YZToast(id: "featuretalk.copy.\(message.id)", message: "复制功能筹备中"))
    }

    private func updateMessageStatus(_ id: YZMessage.ID, status: String) {
        let updated = appState.messages.map { message in
            guard message.id == id else { return message }
            return YZMessage(
                id: message.id,
                direction: message.direction,
                text: message.text,
                statusText: status,
                createdAt: message.createdAt,
                replayable: message.replayable,
                copyable: message.copyable,
                isKeyPoint: message.isKeyPoint
            )
        }
        appState.replaceBaseline(messages: updated)
    }

    private func appendOtherMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastAppendedSpeechText else { return }
        lastAppendedSpeechText = trimmed
        let lastDate = appState.messages.last?.createdAt ?? Date(timeIntervalSince1970: 0)
        let message = YZMessage(
            id: "other.listen.\(UUID().uuidString)",
            direction: .other,
            text: trimmed,
            statusText: "已识别",
            createdAt: max(Date(), lastDate)
        )
        appState.replaceBaseline(messages: appState.messages + [message])
        if appState.selectedView == .phrases {
            appState.selectView(.dialog)
        }
        scrollTargetID = message.id
    }

    private func generateSummary() {
        let items = YZSummaryBuilder.build(messages: appState.messages, scene: appState.selectedScene)
        guard !items.isEmpty else {
            toastCenter.show(YZToast(id: "featuretalk.summary.empty", message: "暂无可归纳的内容"))
            return
        }
        summaryItems = items
        withAnimation(theme.motion.bannerTransitionAnimation) {
            isSummaryVisible = true
        }
    }

    private func copySummary() {
        guard !summaryItems.isEmpty else { return }
        UIPasteboard.general.string = YZSummaryBuilder.copyText(from: summaryItems)
        toastCenter.show(YZToast(id: "featuretalk.summary.copied", message: "要点已复制"))
    }

    private func showLatestSign() {
        speechPlayer.stop()
        let text = appState.messages.last?.text ?? "把手机放在桌上，点下面开始"
        openSign(text, tone: .plain)
    }

    private func openSign(_ text: String, tone: SignTone) {
        speechPlayer.stop()
        signPresentation = SignPresentation(text: text, tone: tone)
    }

    private func openComposer() {
        if speechService.isActive {
            speechService.stop()
        }
        speechPlayer.stop()
        viewModel.openComposer()
    }

    private func closeComposer() {
        viewModel.closeComposer()
    }

    private func submitComposer() {
        guard let id = viewModel.submit(state: appState) else { return }
        scrollTargetID = id
        guard let text = appState.messages.first(where: { $0.id == id })?.text else { return }
        if textOnly {
            updateMessageStatus(id, status: "文字直达")
            return
        }
        speakNow(text, messageID: id)
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let lastID = speechService.partialText.isEmpty
            ? appState.messages.last?.id
            : interimID
        else {
            return
        }
        if animated {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    private var interimID: String {
        "featuretalk.interim"
    }

    private func stopAudio() {
        speechPlayer.stop()
        if speechService.isActive {
            speechService.stop()
        }
    }

    private func closeTalk() {
        stopAudio()
        onClose()
    }
}

private struct TalkListenNoticeContent {
    enum Kind: Equatable {
        case listening
        case reconnecting
        case error
        case blocked
    }

    let kind: Kind
    let message: String
    let dismissible: Bool
}

private struct TalkListenNotice: View {
    let kind: TalkListenNoticeContent.Kind
    let message: String
    let onClose: (() -> Void)?

    @Environment(\.yzTheme) private var theme

    private var isError: Bool {
        kind == .error || kind == .blocked
    }

    var body: some View {
        HStack(spacing: 8) {
            if isError {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            } else {
                Circle()
                    .fill(theme.colors.accent)
                    .frame(width: 7, height: 7)
            }

            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onClose = onClose {
                Button(action: onClose) {
                    Text("关闭")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .frame(minHeight: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressableButtonStyle())
                .accessibilityLabel(Text("关闭提示"))
            }
        }
        .foregroundStyle(isError ? theme.colors.danger : theme.colors.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isError ? theme.colors.dangerSoft : theme.colors.accentSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isError ? theme.colors.dangerStroke : theme.colors.accentStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(message))
        .accessibilityIdentifier("featuretalk.listen.notice")
    }
}

private struct TalkInterimCard: View {
    let text: String

    @Environment(\.yzTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("对方 · 正在说")
                .font(theme.typography.font(for: .cardLabel))
                .foregroundStyle(theme.colors.cardLabelText)

            Text(text)
                .font(theme.typography.font(for: .cardSentence))
                .italic()
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.metrics.spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous)
                .fill(theme.colors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous)
                .strokeBorder(
                    theme.colors.separator,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("对方正在说：\(text)"))
    }
}

private struct TalkDockButton: View {
    enum Kind: Equatable {
        case primary
        case secondary
    }

    let title: String
    let kind: Kind
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.yzTheme) private var theme

    private var foreground: Color {
        guard isEnabled else { return theme.colors.textWeak }
        return kind == .primary ? theme.colors.onAccent : theme.colors.accent
    }

    private var background: Color {
        guard isEnabled else { return theme.colors.sendDisabledFill }
        return kind == .primary ? theme.colors.accentFill : theme.colors.surface
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.font(for: .dockButton))
                .foregroundStyle(foreground)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: theme.metrics.size.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.dockButton, style: .continuous)
                        .fill(background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.dockButton, style: .continuous)
                        .strokeBorder(
                            isEnabled && kind == .secondary
                                ? theme.colors.secondaryButtonStroke
                                : Color.clear,
                            lineWidth: isEnabled && kind == .secondary ? 1 : 0
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(Text(title))
    }
}

struct TalkViewHost: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @State private var appState: YZAppState
    private let themeProvider = YZPlaceholderThemeProvider()
    private let textOnly: Bool
    private let externalClose: (() -> Void)?

    init(
        baseline: YZBaseline = .current,
        textOnly: Bool = false,
        onClose: (() -> Void)? = nil
    ) {
        let phraseBaseline = YZPhraseBaseline.current
        self.textOnly = textOnly
        self.externalClose = onClose
        _appState = State(
            initialValue: YZAppState(
                session: YZMockData.session(baseline: baseline, phraseBaseline: phraseBaseline),
                phraseBaseline: phraseBaseline
            )
        )
    }

    var body: some View {
        TalkView(
            textOnly: textOnly,
            sceneNav: { SceneNavBar(context: $0) },
            phraseContent: { SayListView(context: $0) },
            onClose: {
                if let externalClose = externalClose {
                    externalClose()
                } else {
                    dismiss()
                }
            }
        )
        .environment(\.yzTheme, themeProvider.theme(for: colorScheme, reduceMotion: reduceMotion))
        .environment(appState)
    }
}

#Preview("FeatureTalk") {
    TalkViewHost()
}
#Preview("FeatureTalk 深色") {
    TalkViewHost()
        .preferredColorScheme(.dark)
}

#Preview("FeatureTalk 大字号") {
    TalkViewHost()
        .dynamicTypeSize(.accessibility2)
}