import SwiftUI
import UIKit

@MainActor
struct TalkView: View {
    let onClose: () -> Void

    @Environment(YZAppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedTab: YZTalkTab = .dialog
    @State private var showFaceToFace: Bool
    @State private var isComposerOpen = false
    @State private var draft = ""
    @State private var keyboardObserver = KeyboardHeightObserver()
    @State private var speechService = SpeechService()
    @State private var speechPlayer = SpeechPlayer()
    @State private var signPresentation: SignPresentation?
    @State private var summaryItems: [String] = []
    @State private var isSummaryVisible = false
    @State private var playCounts: [String: Int] = [:]
    @State private var scrollTargetID: String?
    @State private var lastFinalizedID: UUID?
    @State private var localToast: String?

    init(initialFaceToFace: Bool = false, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _showFaceToFace = State(initialValue: initialFaceToFace)
    }

    var body: some View {
        ZStack {
            YZTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if let notice = noticeContent {
                    TalkListenNotice(
                        kind: notice.kind,
                        message: notice.message,
                        onClose: notice.dismissible ? dismissNotice : nil
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                content
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isComposerOpen {
                dock
            }
        }
        .overlay {
            RecordingGlow(isActive: speechService.isActive, reduceMotion: reduceMotion)
        }
        .overlay {
            composerOverlay
        }
        .overlay(alignment: .bottom) {
            if let localToast, !isComposerOpen {
                YZToast(text: localToast)
                    .padding(.horizontal, 20)
                    .padding(.bottom, appState.scene.isEmergency ? 156 : 92)
                    .transition(.opacity)
                    .task(id: localToast) {
                        try? await Task.sleep(for: .seconds(1.8))
                        if self.localToast == localToast {
                            self.localToast = nil
                        }
                    }
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.12), value: selectedTab)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: showFaceToFace)
        .fullScreenCover(item: $signPresentation) { presentation in
            SignView(
                text: presentation.text,
                tone: presentation.tone,
                onDismiss: { signPresentation = nil }
            )
        }
        .onAppear(perform: handleAppear)
        .onDisappear(perform: stopAudio)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                stopAudio()
            case .inactive:
                if speechService.state != .requestingPermission {
                    stopAudio()
                }
            case .active:
                break
            @unknown default:
                break
            }
        }
        .onChange(of: speechService.lastFinalized?.id) { _, _ in
            handleFinalizedSpeech()
        }
        .onChange(of: speechService.state) { _, state in
            if state == .listening {
                UIAccessibility.post(notification: .announcement, argument: "正在听对方说话")
            }
            if state == .blocked || state == .failed {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: speechService.errorMessage ?? ""
                )
            }
        }
        .onChange(of: speechPlayer.lastResult?.id) { _, _ in
            handlePlaybackResult()
        }
        .onChange(of: appState.scene) { _, _ in
            resetForSceneChange()
        }
        .onChange(of: appState.subScene) { _, _ in
            stopAudio()
        }
        .onChange(of: appState.textOnly) { _, newValue in
            if newValue {
                stopAudio()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                Text("译诊")
                    .font(YZTheme.font(size: 18, weight: .semibold, textStyle: .headline, maxSize: 25))
                    .foregroundStyle(YZTheme.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 96)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 8) {
                    closeButton
                    Spacer(minLength: 8)
                    faceToFaceButton
                }
            }
            .frame(minHeight: 44)

            SceneNavBar(
                selectedScene: appState.scene,
                selectedSub: appState.subScene,
                onSelectScene: selectScene,
                onSelectSub: selectSubScene
            )
        }
        .frame(maxWidth: YZTheme.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 6)
        .background {
            ZStack {
                if !YZTheme.highContrast {
                    Rectangle().fill(.ultraThinMaterial)
                }
                Rectangle().fill(YZTheme.card.opacity(YZTheme.highContrast ? 1 : 0.82))
            }
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(YZTheme.line)
                .frame(height: YZTheme.highContrast ? 2 : 1)
        }
        .yzCardShadow()
        .zIndex(20)
    }

    private var closeButton: some View {
        Button(action: closeTalk) {
            Text("关闭")
                .font(YZTheme.font(size: 15, weight: .semibold, textStyle: .body, maxSize: 21))
                .foregroundStyle(YZTheme.blue)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(YZTheme.card, in: Capsule())
                .overlay {
                    Capsule().stroke(
                        YZTheme.highContrast ? Color.black : YZTheme.line,
                        lineWidth: YZTheme.highContrast ? 2 : 1
                    )
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("关闭对话")
    }

    private var faceToFaceButton: some View {
        Button(action: toggleFaceToFace) {
            HStack(spacing: 4) {
                Image(systemName: showFaceToFace ? "person.2.fill" : "person.2")
                    .font(.system(size: 11, weight: .semibold))
                Text("面对面")
                    .font(YZTheme.font(size: 11, weight: .semibold, textStyle: .caption2, maxSize: 15))
                    .lineLimit(1)
            }
            .foregroundStyle(showFaceToFace ? Color.white : YZTheme.blue)
            .padding(.horizontal, 12)
            .frame(minHeight: 32)
            .background(
                Capsule().fill(
                    showFaceToFace
                        ? (YZTheme.highContrast ? Color.black : YZTheme.blueFill)
                        : YZTheme.card
                )
            )
            .overlay {
                Capsule().stroke(
                    YZTheme.highContrast ? Color.black : YZTheme.line,
                    lineWidth: YZTheme.highContrast ? 2 : 1
                )
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("面对面")
        .accessibilityValue(showFaceToFace ? "已开启" : "已关闭")
        .accessibilityHint("切换上下分屏")
    }

    private struct NoticeContent {
        let kind: TalkNoticeKind
        let message: String
        let dismissible: Bool
    }

    private var noticeContent: NoticeContent? {
        if appState.textOnly {
            return NoticeContent(
                kind: .textOnly,
                message: "全程文字模式：不调用麦克风，也不播报。",
                dismissible: false
            )
        }

        switch speechService.state {
        case .requestingPermission:
            return NoticeContent(kind: .listening, message: "正在请求麦克风权限…", dismissible: false)
        case .listening:
            return NoticeContent(kind: .listening, message: "正在听…把手机靠近对方。", dismissible: false)
        case .reconnecting:
            return NoticeContent(kind: .reconnecting, message: "语音识别断开，正在重连…", dismissible: false)
        case .failed:
            return NoticeContent(
                kind: .error,
                message: speechService.errorMessage ?? speechService.failureMessage,
                dismissible: true
            )
        case .blocked:
            return NoticeContent(
                kind: .blocked,
                message: speechService.errorMessage ?? speechService.blockedMessage,
                dismissible: true
            )
        case .idle, .stopping:
            return nil
        }
    }

    @ViewBuilder
    private var content: some View {
        if showFaceToFace {
            FaceView(
                turns: appState.turns,
                scene: appState.scene,
                onOpenSign: { turn in openSign(turn.text, tone: .plain) }
            )
            .frame(maxWidth: YZTheme.contentMaxWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 14)
            .padding(.top, 6)
        } else {
            VStack(spacing: 0) {
                segmentedControl
                    .padding(.top, 10)

                if selectedTab == .dialog {
                    dialogContent
                        .transition(.opacity)
                } else {
                    phrasesContent
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: YZTheme.contentMaxWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 2) {
            ForEach(YZTalkTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(YZTheme.fontPillSmall)
                        .foregroundStyle(
                            tab == selectedTab
                                ? (YZTheme.highContrast ? Color.white : YZTheme.ink)
                                : YZTheme.ink3
                        )
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    tab == selectedTab
                                        ? (YZTheme.highContrast ? Color.black : YZTheme.card)
                                        : Color.clear
                                )
                        )
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressButtonStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(tab == selectedTab ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(YZTheme.bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var dialogContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                summaryButton
            }
            .padding(.top, 4)
            .padding(.bottom, 6)

            if isSummaryVisible, !summaryItems.isEmpty {
                SummaryCard(
                    items: summaryItems,
                    onCopy: copySummary,
                    onCollapse: {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                            isSummaryVisible = false
                        }
                    }
                )
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            conversation
        }
    }

    private var summaryButton: some View {
        Button(action: generateSummary) {
            HStack(spacing: 5) {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 11, weight: .semibold))
                Text("生成要点")
                    .font(YZTheme.font(size: 12, weight: .semibold, textStyle: .caption, maxSize: 17))
                    .lineLimit(1)
            }
            .foregroundStyle(YZTheme.blue)
            .padding(.horizontal, 11)
            .frame(minHeight: 32)
            .background(YZTheme.blueSoft, in: Capsule())
            .overlay {
                Capsule().stroke(
                    YZTheme.highContrast ? Color.black : YZTheme.blueLine,
                    lineWidth: YZTheme.highContrast ? 1.5 : 1
                )
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("生成要点")
    }

    @ViewBuilder
    private var conversation: some View {
        if appState.turns.isEmpty && speechService.partialText.isEmpty {
            VStack(spacing: 0) {
                if let divider = appState.dividerText {
                    Text(divider)
                        .font(YZTheme.font(size: 11, textStyle: .caption2, maxSize: 16))
                        .foregroundStyle(YZTheme.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .accessibilityLabel(divider)
                }
                TalkEmptyState(textOnly: appState.textOnly)
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if let divider = appState.dividerText {
                            Text(divider)
                                .font(YZTheme.font(size: 11, textStyle: .caption2, maxSize: 16))
                                .foregroundStyle(YZTheme.ink3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .accessibilityLabel(divider)
                        }

                        ForEach(appState.turns) { turn in
                            VStack(spacing: 6) {
                                TalkMessageCard(
                                    turn: turn,
                                    scene: appState.scene,
                                    onReplay: { replay(turn) },
                                    onCopy: { copyText(turn.text) },
                                    onOpenSign: { openSign(turn.text, tone: .plain) }
                                )

                                if turn.role == .other,
                                   turn.id == latestOtherTurnID,
                                   let term = TermMatcher.match(turn.text, in: appState.terms) {
                                    TermHint(term: term, scene: appState.scene)
                                }
                            }
                            .id(turn.id.uuidString)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                        }

                        if !speechService.partialText.isEmpty {
                            TalkInterimCard(text: speechService.partialText)
                                .id(interimID)
                        }
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.18),
                    value: appState.turns.last?.id
                )
                .onAppear {
                    scrollToLatest(proxy, animated: false)
                }
                .onChange(of: appState.turns.last?.id) { _, _ in
                    scrollToLatest(proxy, animated: !reduceMotion)
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

    private var phrasesContent: some View {
        SayList(
            items: appState.phrases(for: appState.scene, subScene: appState.subScene),
            subSceneName: appState.subScene,
            playCounts: $playCounts,
            onSelect: usePhrase
        )
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dock: some View {
        VStack(spacing: 8) {
            if appState.scene.isEmergency {
                TalkEmergencyBanner(text: "我听不见，请帮我打 120。") {
                    openSign("我听不见，请帮我打 120。", tone: .emergency)
                }
            }

            HStack(spacing: 8) {
                TalkDockButton(
                    title: speechService.isActive ? "停止聆听" : "听对方说",
                    kind: .primary,
                    isEnabled: !appState.textOnly && !speechService.isBlocked,
                    action: toggleListening
                )

                TalkDockButton(
                    title: "我要说",
                    kind: .secondary,
                    isEnabled: true,
                    action: openComposer
                )

                TalkDockButton(
                    title: "全屏",
                    kind: .secondary,
                    isEnabled: true,
                    action: showLatestSign
                )
            }
        }
        .frame(maxWidth: YZTheme.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background {
            ZStack {
                if !YZTheme.highContrast {
                    Rectangle().fill(.ultraThinMaterial)
                }
                Rectangle().fill(YZTheme.card.opacity(YZTheme.highContrast ? 1 : 0.92))
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(YZTheme.line)
                .frame(height: YZTheme.highContrast ? 2 : 1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var composerOverlay: some View {
        if isComposerOpen {
            ZStack(alignment: .bottom) {
                YZTheme.scrim
                    .ignoresSafeArea()
                    .onTapGesture(perform: closeComposer)
                    .accessibilityHidden(true)

                TalkComposer(
                    draft: $draft,
                    canSend: canSendDraft,
                    term: draftTerm,
                    scene: appState.scene,
                    textOnly: appState.textOnly,
                    onSend: submitComposer,
                    onClose: closeComposer
                )
                .padding(.bottom, keyboardObserver.height)
            }
            .ignoresSafeArea(edges: .bottom)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: isComposerOpen)
            .zIndex(100)
        }
    }

    private var latestOtherTurnID: UUID? {
        appState.turns.last(where: { $0.role == .other })?.id
    }

    private var interimID: String {
        "talk.interim"
    }

    private var draftTerm: Term? {
        TermMatcher.match(draft, in: appState.terms)
    }

    private var canSendDraft: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleAppear() {
        if let pending = appState.takePendingSpeech(), !appState.textOnly {
            speakNow(pending.text, turnID: pending.turnID)
        }
    }

    private func selectScene(_ scene: SceneKind) {
        flushSpeech()
        closeComposer()
        summaryItems = []
        isSummaryVisible = false
        playCounts = [:]
        appState.switchScene(to: scene)
    }

    private func selectSubScene(_ sub: String) {
        flushSpeech()
        appState.switchSubScene(to: sub)
    }

    private func resetForSceneChange() {
        stopAudio()
        summaryItems = []
        isSummaryVisible = false
        playCounts = [:]
        scrollTargetID = appState.turns.last?.id.uuidString
        if appState.textOnly {
            speechService.clearError()
        }
    }

    private func dismissNotice() {
        speechService.clearError()
    }

    private func toggleListening() {
        if speechService.isActive {
            speechService.stop()
            return
        }
        guard !speechService.isBlocked, !appState.textOnly else { return }
        speechPlayer.stop()
        selectedTab = .dialog
        speechService.start()
    }

    private func handleFinalizedSpeech() {
        guard let finalized = speechService.lastFinalized else { return }
        guard finalized.id != lastFinalizedID else { return }
        lastFinalizedID = finalized.id

        let text = finalized.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let id = appState.appendTurn(role: .other, text: text, status: "已识别")
        if selectedTab == .phrases {
            selectedTab = .dialog
        }
        scrollTargetID = id.uuidString
    }

    private func handlePlaybackResult() {
        guard let result = speechPlayer.lastResult else { return }
        guard
            let raw = result.messageID,
            let turnID = UUID(uuidString: raw)
        else { return }

        appState.updateTurnStatus(id: turnID, status: result.success ? "已播报" : "播报失败")
        if !result.success {
            showToast("播报失败，请继续用文字沟通。")
            UIAccessibility.post(notification: .announcement, argument: "播报失败，请用文字沟通")
        }
    }

    private func speakNow(_ text: String, turnID: UUID?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if speechService.isActive {
            speechService.stop()
        }
        if let turnID {
            appState.updateTurnStatus(id: turnID, status: "已播报")
        }
        speechPlayer.speak(value, messageID: turnID?.uuidString)
    }

    private func replay(_ turn: YZTurn) {
        guard turn.role == .me else {
            openSign(turn.text, tone: .plain)
            return
        }
        guard !appState.textOnly else {
            appState.updateTurnStatus(id: turn.id, status: "文字直达")
            return
        }
        speakNow(turn.text, turnID: turn.id)
    }

    private func copyText(_ text: String) {
        UIPasteboard.general.string = text
        showToast("已复制")
    }

    private func usePhrase(_ text: String) {
        let status = appState.textOnly ? "文字直达" : "待播报"

        if let last = appState.turns.last, last.role == .me, last.text == text {
            appState.updateTurnStatus(id: last.id, status: status)
            if !appState.textOnly {
                speakNow(text, turnID: last.id)
                showToast("正在播给对方听")
            } else {
                showToast("已发到对话里")
            }
            return
        }

        let id = appState.appendTurn(role: .me, text: text, status: status)
        if appState.textOnly {
            showToast("已发到对话里")
            scrollTargetID = id.uuidString
            return
        }

        scrollTargetID = id.uuidString
        speakNow(text, turnID: id)
        showToast("正在播给对方听")
    }

    private func generateSummary() {
        let items = YZSummaryBuilder.build(turns: appState.turns, scene: appState.scene)
        guard !items.isEmpty else {
            showToast("暂无可归纳的内容")
            return
        }

        summaryItems = items
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            isSummaryVisible = true
        }
    }

    private func copySummary() {
        guard !summaryItems.isEmpty else { return }
        UIPasteboard.general.string = YZSummaryBuilder.copyText(from: summaryItems)
        showToast("要点已复制")
    }

    private func showLatestSign() {
        speechPlayer.stop()
        let text = appState.turns.last?.text ?? "把手机放在桌上，点下面开始"
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
        selectedTab = .dialog
        isComposerOpen = true
    }

    private func closeComposer() {
        isComposerOpen = false
    }

    private func submitComposer() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        let status = appState.textOnly ? "文字直达" : "待播报"
        let id = appState.appendTurn(role: .me, text: value, status: status)
        draft = ""
        selectedTab = .dialog
        scrollTargetID = id.uuidString

        if !appState.textOnly {
            speakNow(value, turnID: id)
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy, animated: Bool) {
        let lastID: String? = speechService.partialText.isEmpty
            ? appState.turns.last?.id.uuidString
            : interimID

        guard let lastID else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    private func stopAudio() {
        speechPlayer.stop()
        if speechService.isActive || speechService.state == .failed || speechService.state == .blocked {
            speechService.stop()
        }
    }

    private func closeTalk() {
        flushSpeech()
        onClose()
    }

    private func flushSpeech() {
        stopAudio()
        guard let finalized = speechService.lastFinalized else { return }
        guard finalized.id != lastFinalizedID else { return }
        lastFinalizedID = finalized.id

        let text = finalized.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        appState.appendTurn(role: .other, text: text, status: "已识别")
    }

    private func showToast(_ text: String) {
        localToast = text
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}
