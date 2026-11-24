import SwiftUI

struct DialogueView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showSign = false
    @State private var showScene = false
    @State private var phoneTools = false
    @State private var captionGuide = false
    @State private var showCallDetails = false
    @State private var showCustomPhrases = false
    @State private var showPhraseOrder = false
    private var manualText: String {
        get { app.quickSpeechDraft }
        nonmutating set { app.quickSpeechDraft = newValue }
    }
    private var listeningMode: Bool { app.conversation.isFaceToFace }
    @State private var confirmComplete = false
    @State private var showCallConfirmation = false
    @State private var phoneToConfirm: CustomerPhone?
    @State private var orderExpanded = false
    @FocusState private var editing: Bool

    private var suggestions: [String] {
        app.dialogueEntry == .pickup ? ["我是听障骑手，请用文字沟通"] : app.dialogueEntry == .delivery ? PhraseShortcut.riderTexts : PhraseShortcut.phoneTexts
    }
    private var pickupSentence: String {
        var text = "您好，我来取餐。"
        if !app.pickup.code.isEmpty { text += "取餐码是\(app.pickup.code)。" }
        if !app.pickup.phone.isEmpty { text += "手机尾号\(app.pickup.phone.suffix(4))。" }
        return text + "我是听障骑手，请用文字和我沟通，谢谢。"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("沟通方式", selection: Binding(get: { listeningMode }, set: { app.conversation.isFaceToFace = $0 })) {
                    Text("电话辅助").tag(false)
                    Text("面对面聊天").tag(true)
                }.pickerStyle(.segmented).padding(.horizontal, 20).padding(.vertical, 12)
                    .accessibilityIdentifier("dialogue.mode")
                if let scene = app.activeScene {
                    Button {
                        app.conversation.stopAll()
                        app.conversation.setVisible(false)
                        showScene = true
                    } label: {
                        HStack { Label(scene.displayTitle + " · 查看资料", systemImage: "doc.text"); Spacer(); Image(systemName: "chevron.right") }
                            .font(.subheadline.weight(.semibold)).padding(.horizontal, 20).frame(minHeight: 44)
                    }.accessibilityIdentifier("dialogue.scene")
                }
                if listeningMode {
                    if app.dialogueEntry == .delivery { compactDeliveryContext }
                    FaceToFaceView()
                }
                else {
                    callStatus.padding(.horizontal, 20).padding(.bottom, 4)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            Button { editing = false; captionGuide = true } label: {
                                HStack {
                                    Label("看对方的话", systemImage: "captions.bubble")
                                    Spacer()
                                    Text("设置实时字幕").font(.subheadline)
                                    Image(systemName: "chevron.right").font(.caption)
                                }.padding(.horizontal, 14).frame(minHeight: 46).ylctLens(15, touch: true)
                            }.buttonStyle(.plain).accessibilityIdentifier("phone.captions")
                            contextCard
                            if app.dialogueEntry.serviceMode == nil {
                                Button { phoneTools = true } label: { Label("拨号与联系人", systemImage: "phone").padding(.horizontal, 16).frame(minHeight: 44).ylctGlass(Capsule(), touch: true) }
                            }
                            if !app.opening.notice.isEmpty {
                                HStack {
                                    Text(app.opening.notice).font(.footnote)
                                    Spacer()
                                    if app.opening.pending { Button("取消开场") { app.opening.cancel("本次不自动播报。") } }
                                }
                            }
                            voicePicker
                            suggestionsCard
                            if !app.injection.lastSpoken.isEmpty { lastSpoken }
                            if app.dialogueEntry == .delivery, let id = app.activeDeliveryID {
                                Button { confirmComplete = true } label: {
                                    Label(app.currentDeliveryCompleted ? "这一单已记入记录" : "这单已送达，记一单", systemImage: "checkmark.circle")
                                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
                                }.disabled(app.currentDeliveryCompleted).foregroundStyle(Color.ylctMint)
                                    .confirmationDialog("确认已经送达？", isPresented: $confirmComplete, titleVisibility: .visible) {
                                        Button("确认完成") { app.completeOrder(id: id) }
                                    }
                            }
                        }.ylctGroup().padding(20)
                    }.scrollDismissesKeyboard(.interactively).safeAreaInset(edge: .bottom) { composer }
                }
            }.background(YLCTBackground())
                .navigationTitle(listeningMode ? "面对面沟通" : app.dialogueEntry == .delivery ? "送餐 · 电话沟通" : app.dialogueEntry == .pickup ? "取餐沟通" : "电话辅助")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss() } }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { app.conversation.stopAll(); showSign = true } label: {
                            Label("大字牌", systemImage: "textformat.size")
                        }.font(.subheadline.weight(.semibold))
                    }
                    ToolbarItemGroup(placement: .keyboard) { if !listeningMode { Spacer(); Button("完成") { editing = false } } }
                }
                .sheet(isPresented: $showScene, onDismiss: { app.conversation.setVisible(listeningMode) }) {
                    if let scene = app.activeScene {
                        SceneContextSheet(scene: scene) { line in
                            if listeningMode {
                                let draft = app.conversation.log.draft
                                app.conversation.log.draft = draft.isEmpty ? line : draft + "\n" + line
                                if app.sessionPreference == .captions { app.sessionPreference = .spokenReply }
                            } else {
                                let draft = app.quickSpeechDraft
                                app.quickSpeechDraft = draft.isEmpty ? line : draft + "\n" + line
                            }
                        }
                    }
                }
                .sheet(isPresented: $captionGuide) {
                    NavigationStack { LiveCaptionGuide().toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("完成") { captionGuide = false } }
                    } }.presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $phoneTools) { PhoneToolsView() }
                .sheet(isPresented: $showCallDetails) { CallInjectionDetails().environmentObject(app).presentationDetents([.height(340), .medium]) }
                .sheet(isPresented: $showCustomPhrases) { CustomPhrasesView().environmentObject(app) }
                .sheet(isPresented: $showPhraseOrder) { PhraseOrderView(library: app.customPhrases) }
                .fullScreenCover(isPresented: $showSign, onDismiss: { app.conversation.setVisible(listeningMode) }) {
                    SignView(showPickupCode: app.dialogueEntry == .pickup).environmentObject(app)
                }
        }.tint(.ylctBlue)
            .onAppear {
                app.conversation.setVisible(listeningMode)
            }
            .task {
                app.consumePendingPhone()
                if app.startCaptionOnOpen && listeningMode {
                    app.startCaptionOnOpen = false
                    app.conversation.setVisible(true)
                    app.conversation.startListening()
                }
            }
            .alert("电话提示", isPresented: Binding(get: { app.externalActionMessage != nil && !showScene }, set: { if !$0 { app.externalActionMessage = nil } })) {
                Button("知道了", role: .cancel) { app.externalActionMessage = nil }
            } message: { Text(app.externalActionMessage ?? "") }
            .onChange(of: listeningMode) { _, listening in
                editing = false
                if listening { app.opening.cancel("") }
                app.conversation.stopAll()
                app.conversation.setVisible(listening)
            }
            .onDisappear { app.opening.cancel(""); app.conversation.setVisible(false); app.injection.stopSpeaking() }
    }

    private var voicePicker: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Label("播报声音", systemImage: "speaker.wave.2").font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
            if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
            Picker("播报声音", selection: Binding(get: { app.injection.voiceGender }, set: { app.injection.setVoice($0) })) {
                Text("女声 · 冰糖").tag("female")
                Text("男声 · 苏打").tag("male")
            }.pickerStyle(.menu).font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("点一句，帮你说").font(.headline).foregroundStyle(Color.ylctText)
                Spacer()
                Button("排序") { app.conversation.stopAll(); showPhraseOrder = true }
                    .font(.subheadline.weight(.semibold)).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("phrases.sort-direct")
                    .accessibilityHint("一起调整系统预设和自定义语音的顺序")
                Button { app.conversation.stopAll(); showCustomPhrases = true } label: {
                    Text("管理").font(.subheadline.weight(.semibold)).frame(minWidth: 44, minHeight: 44)
                }.accessibilityIdentifier("phrases.manage")
                    .accessibilityLabel("管理常用语")
            }
            ForEach(app.visibleShortcuts(including: suggestions)) { shortcut in
                let sourceID = "quick.\(shortcut.id)"
                let snapshot = app.injection.playback.sourceID == sourceID ? app.injection.playback : nil
                Button {
                    if snapshot?.phase.isBusy == true { app.injection.stopSpeaking() }
                    else { app.speak(shortcut.text, sourceID: sourceID) }
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: snapshot?.phase.isBusy == true ? "stop.fill" : "speaker.wave.2.fill").foregroundStyle(Color.ylctBlue).frame(width: 22)
                        Text(shortcut.text).font(.body.weight(.medium)).foregroundStyle(Color.ylctText).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }.padding(16).frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                        .playbackFill(snapshot, radius: 18)
                        .ylctLens(18, tint: shortcut.custom != nil ? .ylctBlue.opacity(0.12) : nil, touch: true)
                }.buttonStyle(PressStyle()).disabled(shortcut.custom.map { !app.customPhrases.ready($0) } ?? false)
                    .accessibilityLabel(shortcut.custom != nil ? "播报我的常用语：\(shortcut.text)" : "播报：\(shortcut.text)")
                    .playbackAccessibilityValue(snapshot)
                    .accessibilityIdentifier("phrases.quick.\(shortcut.id)").accessibilityHint(snapshot?.phase.isBusy == true ? "再次点按停止播报" : "使用本机常用语音频")
            }
        }
    }
    @ViewBuilder private var contextCard: some View {
        if app.dialogueEntry == .pickup, !app.pickup.code.isEmpty || !app.pickup.merchant.isEmpty || !app.pickup.phone.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(app.pickup.merchant.isEmpty ? "这一单的取餐信息" : app.pickup.merchant, systemImage: "bag.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctMint)
                if !app.pickup.code.isEmpty {
                    Text(app.pickup.code).font(.system(.largeTitle, design: .rounded, weight: .bold)).foregroundStyle(Color.ylctText).textSelection(.enabled)
                }
                if !app.pickup.phone.isEmpty { Text("手机尾号 \(app.pickup.phone.suffix(4))").font(.subheadline).foregroundStyle(Color.ylctTextSecondary) }
                let snapshot = app.injection.playback.sourceID == "pickup" ? app.injection.playback : nil
                Button {
                    if snapshot?.phase.isBusy == true { app.injection.stopSpeaking() }
                    else { app.speak(pickupSentence, usePreset: false, sourceID: "pickup") }
                } label: {
                    Label("播报取餐信息 · 系统语音", systemImage: snapshot?.phase.isBusy == true ? "stop.fill" : "speaker.wave.2")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(10).playbackFill(snapshot, radius: 12)
                }.foregroundStyle(Color.ylctBlue)
                    .accessibilityIdentifier("pickup.speak")
                    .playbackAccessibilityValue(snapshot)
            }.frame(maxWidth: .infinity, alignment: .leading).ylctCard()
        } else if app.dialogueEntry == .delivery {
            deliveryDetails.ylctCard(padding: 16)
        }
    }
    private var deliveryDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("这一单送到", systemImage: "mappin.and.ellipse").font(.caption.weight(.semibold)).foregroundStyle(Color.ylctBlue)
            Text(app.address.summary.isEmpty ? "还没有填写送达地址" : app.address.summary)
                .font(.headline).foregroundStyle(Color.ylctText).textSelection(.enabled).accessibilityIdentifier("delivery.context-address")
            if !app.address.note.isEmpty {
                Label("送达备注：\(app.address.note)", systemImage: "note.text")
                    .font(.subheadline.weight(.medium)).foregroundStyle(Color.ylctOrange).accessibilityIdentifier("delivery.context-note")
            }
            if let phone = app.address.customerPhone {
                Text("顾客电话 \(phone.number)").font(.subheadline).foregroundStyle(Color.ylctTextSecondary).textSelection(.enabled)
            } else {
                Text(app.address.phone.isEmpty ? "未填电话，可返回地址页补充" : "号码不完整，核对后才能拨号").font(.caption).foregroundStyle(Color.ylctTextSecondary)
            }
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 12))
            layout {
                OrderActionButton(title: "联系顾客", icon: "phone.fill") {
                    phoneToConfirm = app.address.customerPhone
                    showCallConfirmation = phoneToConfirm != nil
                }.disabled(app.address.customerPhone == nil).accessibilityIdentifier("dialogue.call-customer")
                OrderActionButton(title: "地址与导航", icon: "map") { app.returnToDeliveryAddress() }
                    .accessibilityIdentifier("dialogue.return-address")
            }
            if !app.address.summary.isEmpty, !listeningMode {
                Button {
                    app.prepareAddressQuestion()
                    editing = true
                } label: {
                    Label("问一句地址对不对", systemImage: "text.quote").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }.accessibilityIdentifier("delivery.address-question")
            }
            if !listeningMode { Text("先电话联系，到现场再切「面对面聊天」。").font(.caption).foregroundStyle(Color.ylctTextSecondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .alert("核对顾客号码", isPresented: $showCallConfirmation, presenting: phoneToConfirm) { phone in
                Button("拨打 \(phone.number)") { app.dialCustomer(phone) }
                Button("复制号码") { UIPasteboard.general.string = phone.number }
                Button("取消", role: .cancel) {}
            } message: { phone in Text("\(phone.number)\n将打开系统拨号；不会自动播报文字。") }
    }
    private var compactDeliveryContext: some View {
        DisclosureGroup(isExpanded: $orderExpanded) {
            ScrollView { deliveryDetails.padding(.top, 12) }.frame(maxHeight: typeSize.isAccessibilitySize ? 320 : 260)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Label(app.address.summary.isEmpty ? "这一单 · 查看地址和电话" : app.address.summary, systemImage: "mappin.and.ellipse")
                    .font(.subheadline.weight(.semibold)).lineLimit(2).foregroundStyle(Color.ylctText)
                if !app.address.note.isEmpty { Text("备注：\(app.address.note)").font(.caption).lineLimit(1).foregroundStyle(Color.ylctOrange) }
            }
        }.accessibilityIdentifier("delivery.context-disclosure").tint(.ylctBlue)
            .padding(12).background(Color.ylctSurface, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20).padding(.bottom, 8)
    }
    private var lastSpoken: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("这次播报", systemImage: "waveform").font(.caption.weight(.semibold)).foregroundStyle(Color.ylctTextSecondary)
                Spacer()
            }
            Text(app.injection.lastSpoken).font(.body).foregroundStyle(Color.ylctText).textSelection(.enabled)
            if !app.injection.outputNotice.isEmpty { Text(app.injection.outputNotice).font(.subheadline).foregroundStyle(Color.ylctDanger) }
        }.ylctCard(padding: 16)
    }
    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if app.injection.playback.id != nil {
                HStack(spacing: 12) {
                    PlaybackProgressView(snapshot: app.injection.playback, identifier: "playback.quick.pinned")
                    if app.injection.playback.phase.isBusy {
                        Button { app.injection.stopSpeaking() } label: {
                            Image(systemName: "stop.fill").frame(width: 44, height: 44)
                        }.foregroundStyle(Color.ylctDanger).accessibilityLabel("停止播报").accessibilityIdentifier("playback.quick.stop")
                    }
                }
            }
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout())
            layout {
                Text("自己打字，替你说").font(.caption.weight(.semibold))
                if !typeSize.isAccessibilitySize { Spacer() }
                Text("系统语音 · 输入后直接播报").font(.caption2)
            }.foregroundStyle(Color.ylctTextSecondary)
            HStack(alignment: .bottom, spacing: 10) {
                TextField("输入想说的话…", text: Binding(get: { manualText }, set: { manualText = $0 }), axis: .vertical)
                    .accessibilityIdentifier("dialogue.quick-draft")
                    .lineLimit(1...4).font(.body).padding(14).foregroundStyle(Color.ylctText)
                    .background(Color.ylctField, in: RoundedRectangle(cornerRadius: 16)).focused($editing)
                    .accessibilityLabel("要播报的文字")
                Button(action: sendManual) {
                    Image(systemName: "speaker.wave.2.fill").font(.headline).foregroundStyle(.white)
                        .frame(width: 50, height: 50).ylctLens(16, tint: .ylctAction, solid: .ylctAction, touch: true)
                }.buttonStyle(PressStyle()).disabled(manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    .accessibilityLabel("播报输入的文字")
            }
        }.padding(16).ylctDock()
    }
    private func sendManual() {
        let text = manualText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        editing = false
        app.speak(text, usePreset: false, sourceID: "manual")
    }
    private var callStatus: some View {
        let state = app.injection.injectionState
        let color: Color = state == .ready ? .ylctMint : state == .waiting || state == .off ? .ylctTextSecondary : .ylctOrange
        return Button { showCallDetails = true } label: {
            HStack(spacing: 8) {
                Image(systemName: state.symbol)
                Text(state.title).lineLimit(1)
                Spacer(minLength: 4)
                Text(state.needsSettings ? "去设置" : "详情").font(.caption)
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
            }.font(.caption.weight(.semibold)).foregroundStyle(color)
                .padding(.horizontal, 12).frame(minHeight: 44)
                .ylctLens(12, tint: color.opacity(0.12), touch: true)
        }.buttonStyle(.plain).accessibilityIdentifier("call.status")
            .accessibilityLabel(state.title).accessibilityHint("查看通话注入状态和设置")
    }
}

private struct CallInjectionDetails: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var changing = false
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Label(app.injection.injectionState.title, systemImage: app.injection.injectionState.symbol)
                    .font(.headline).foregroundStyle(Color.ylctText)
                Text(app.injection.injectionState.detail).font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    .accessibilityIdentifier("call.status-detail")
                if app.injection.statusText.hasPrefix("请手动打开") {
                    Text(app.injection.statusText).font(.caption).foregroundStyle(Color.ylctOrange)
                }
                if app.injection.injectionState.needsSettings {
                    PrimaryButton(title: "打开系统设置", systemImage: "gearshape") { app.injection.openAccessibilitySettings() }
                } else {
                    PrimaryButton(title: changing ? "处理中…" : app.injection.injectionEnabled ? "关闭通话注入" : "开启通话注入", systemImage: "phone.badge.waveform") {
                        changing = true
                        Task { await app.toggleInjection(); changing = false }
                    }.disabled(changing).accessibilityIdentifier("call.toggle")
                }
                if app.injection.callActive {
                    Text("通话期间请用文字播报；现场转写暂不可用。").font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }
                Spacer(minLength: 0)
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(YLCTBackground())
                .navigationTitle("通话注入").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() }.accessibilityIdentifier("call.details-done") } }
        }.tint(.ylctBlue)
    }
}

private struct PresentedMessage: Identifiable {
    let id = UUID()
    let text: String
}

private struct FaceToFaceView: View {
    @ScaledMetric(relativeTo: .subheadline) private var replyStripHeight: CGFloat = 48
    @EnvironmentObject private var app: AppState
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var saveFeedback: String?
    private var silent: Bool { app.sessionPreference == .textOnly }
    @State private var confirmClear = false
    @State private var showHelp = false
    @State private var showCustomPhrases = false
    @State private var showPartnerInput = false
    @State private var presentedMessage: PresentedMessage?
    @State private var followsLatest = true
    @FocusState private var editing: Bool
    private var conversation: FaceToFaceConversation { app.conversation }
    private var draft: Binding<String> { Binding(get: { conversation.log.draft }, set: { conversation.log.draft = $0 }) }
    private var cleanDraft: String { conversation.log.draft.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var quickReplies: [String] {
        var replies = PhraseShortcut.faceTexts
        if app.dialogueEntry == .pickup, !app.pickup.code.isEmpty {
            let spokenCode = app.pickup.code.map(String.init).joined(separator: " ")
            replies.insert("您好，我来取餐，取餐码是 \(spokenCode)。", at: 0)
        }
        return replies
    }
    private var busy: Bool { app.injection.playback.phase.isBusy }
    private var status: String {
        if silent { return "双方打字 · 静音" }
        if app.injection.callActive { return "通话中 · 现场转写暂停" }
        if conversation.requesting { return "正在检查麦克风权限" }
        if busy { return "\(app.injection.playback.phase.label) · 麦克风暂停" }
        if app.speech.isRecording { return "正在听对方说 · 实时转写" }
        if conversation.listening.requested { return "正在接回麦克风" }
        return "麦克风已暂停"
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label(status, systemImage: app.speech.isRecording ? "mic.fill" : busy ? "speaker.wave.2.fill" : "mic.slash.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(app.speech.isRecording ? Color.ylctMint : Color.ylctTextSecondary)
                    .accessibilityAddTraits(.updatesFrequently)
                Spacer(minLength: 0)
                if editing, app.speech.isRecording || busy {
                    Button(busy ? "停止" : "暂停") { conversation.stopAll() }
                        .font(.subheadline.weight(.semibold)).frame(minWidth: 44, minHeight: 44)
                }
                Menu {
                    ForEach(CommunicationPreference.allCases) { choice in
                        Button(choice.title, systemImage: choice.icon) {
                            conversation.stopAll()
                            app.sessionPreference = choice
                        }
                    }
                    Button("保存本次对话", systemImage: "square.and.arrow.down") {
                        saveFeedback = app.saveCurrentConversation() ? "已保存，可在「我的 → 保存的对话」查看。" : app.universal.error
                    }.disabled(conversation.log.messages.isEmpty)
                    Button("使用说明", systemImage: "questionmark.circle") { showHelp = true }
                    Button("清空本次对话", systemImage: "trash", role: .destructive) { confirmClear = true }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3).frame(width: 44, height: 44)
                }.accessibilityLabel("对话设置")
            }.padding(.horizontal, 20)
            if !conversation.notice.isEmpty || !app.injection.outputNotice.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    if !conversation.notice.isEmpty { Text(conversation.notice) }
                    if !app.injection.outputNotice.isEmpty { Text(app.injection.outputNotice) }
                    if app.speech.needsSettings, !conversation.notice.isEmpty {
                        Button("打开设置，允许麦克风与语音识别") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }.frame(minHeight: 44)
                    }
                }.font(.subheadline).foregroundStyle(Color.ylctDanger).frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.bottom, 10)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if conversation.log.messages.isEmpty { introduction }
                        ForEach(conversation.log.messages) { message in messageBubble(message) }
                        if app.speech.isRecording {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("对方 · 正在说", systemImage: "waveform").font(.caption.weight(.semibold)).foregroundStyle(Color.ylctMint)
                                Text(app.speech.transcript.isEmpty ? "请对方靠近手机，说话会显示在这里…" : app.speech.transcript)
                                    .font(.title3).foregroundStyle(app.speech.transcript.isEmpty ? Color.ylctTextSecondary : Color.ylctText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }.ylctCard(radius: 20, padding: 16)
                        }
                        Color.clear.frame(height: 1).id("conversation-bottom")
                    }.padding(20)
                }.scrollDismissesKeyboard(.interactively)
                    .simultaneousGesture(DragGesture().onChanged { _ in followsLatest = false })
                    .onChange(of: conversation.log.messages.count) { _, _ in if followsLatest { proxy.scrollTo("conversation-bottom", anchor: .bottom) } }
                    .onChange(of: app.speech.transcript) { _, _ in if followsLatest { proxy.scrollTo("conversation-bottom", anchor: .bottom) } }
                    .onChange(of: editing) { _, value in if value { followsLatest = true; proxy.scrollTo("conversation-bottom", anchor: .bottom) } }
                    .overlay(alignment: .bottomTrailing) {
                        if !followsLatest {
                            Button { followsLatest = true; proxy.scrollTo("conversation-bottom", anchor: .bottom) } label: {
                                Label("查看最新", systemImage: "arrow.down").font(.subheadline.weight(.semibold)).padding(12).ylctGlass(Capsule(), touch: true)
                            }.padding(16)
                        }
                    }
            }
        }.safeAreaInset(edge: .bottom, spacing: 0) { conversationComposer }
            .confirmationDialog("清空消息和未发送的草稿？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空本次对话", role: .destructive) { conversation.clear() }
            } message: { Text("清空后无法恢复。关闭页面仍保留对话；清空或应用进程结束后移除。") }
            .sheet(isPresented: $showCustomPhrases, onDismiss: { conversation.setVisible(true) }) { CustomPhrasesView().environmentObject(app) }
            .sheet(isPresented: $showPartnerInput, onDismiss: { conversation.setVisible(true) }) {
                PartnerInputView(text: Binding(get: { conversation.partnerDraft }, set: { conversation.partnerDraft = $0 })) { text in conversation.addTypedResponse(text) }
            }
            .fullScreenCover(item: $presentedMessage, onDismiss: { conversation.setVisible(true) }) { message in
                MessageDisplayView(text: message.text)
            }
            .alert("保存对话", isPresented: Binding(get: { saveFeedback != nil }, set: { if !$0 { saveFeedback = nil } })) {
                Button("知道了") { saveFeedback = nil }
            } message: { Text(saveFeedback ?? "") }
            .alert("面对面沟通说明", isPresented: $showHelp) { Button("知道了", role: .cancel) {} } message: {
                Text("点「开始听」后，对方的话实时转成文字。输入回复点「播报」，使用系统语音直接说出；麦克风会暂停，播完后继续听。\n\n常用回复始终显示在输入框上方，左右滑动查看更多。自带回复的 MiMo 男女声已随 App 安装，无需联网。自定义回复在添加时生成并保存两种声音，之后离线播放。临时输入的信息使用系统语音。\n\n播报结束不等于对方听清，请当面确认。转写可能有误，人名、金额和时间请再次核对。\n\n在更多菜单中点「保存本次对话」可保存文字。设备支持时使用本机识别，否则由系统语音服务处理。")
            }
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("收起键盘") { editing = false } } }
            .onAppear { app.injection.refreshOutputNotice() }
    }
    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(silent ? "双方轮流打字" : "面对面交流").font(.title2.bold())
            Text(silent ? "输入后点「发送」。轮到对方时，点「请对方打字」把手机递过去。" : "点「开始听」显示现场字幕。需要回应时，可以播报或把文字展示给对方。")
                .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading).ylctCard()
    }
    private func messageBubble(_ message: ConversationMessage) -> some View {
        let own = message.speaker == .me
        return HStack(alignment: .top, spacing: 20) {
            if own { Spacer(minLength: typeSize.isAccessibilitySize ? 0 : 24) }
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Label(own ? "我" : message.isTranscribed ? "对方 · 转写" : "对方 · 打字", systemImage: own ? "keyboard" : "text.bubble")
                    Spacer()
                    Text(message.date, style: .time)
                }.font(.caption.weight(.semibold)).foregroundStyle(own ? Color.ylctBlue : Color.ylctTextSecondary)
                Text(message.text).font(.title3.weight(.medium)).foregroundStyle(Color.ylctText).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                if own && !message.isTextOnly {
                    Label(message.playback.label, systemImage: message.playback == .completed ? "checkmark.circle" : message.playback == .playing ? "waveform" : "speaker.wave.2")
                        .font(.caption.weight(.medium)).foregroundStyle(message.playback == .failed ? Color.ylctDanger : Color.ylctTextSecondary)
                } else if message.isTranscribed {
                    Text("请核对人名、数字和地址").font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 18) { messageActions(message) }
                    VStack(alignment: .leading, spacing: 0) { messageActions(message) }
                }
            }.font(.subheadline.weight(.semibold)).padding(16).background(own ? Color.ylctBlue.opacity(0.09) : Color.ylctSurface, in: RoundedRectangle(cornerRadius: 20))
                .overlay { RoundedRectangle(cornerRadius: 20).stroke(own ? Color.ylctBlue.opacity(0.25) : Color.ylctStroke, lineWidth: 1) }
            if !own { Spacer(minLength: typeSize.isAccessibilitySize ? 0 : 24) }
        }
    }
    @ViewBuilder private func messageActions(_ message: ConversationMessage) -> some View {
        if message.speaker == .me && !silent && !message.isTextOnly {
            Button { followsLatest = true; conversation.playMessage(message.id) } label: {
                Label("重播", systemImage: "arrow.clockwise").padding(.horizontal, 10).frame(minHeight: 44)
                    .playbackFill(message.playbackSnapshot, radius: 10)
            }
                .disabled(busy || app.injection.callActive).frame(minHeight: 44)
        }
        Button { display(message.text) } label: { Label("放大", systemImage: "arrow.up.left.and.arrow.down.right") }.frame(minHeight: 44)
        Menu {
            Button("复制文字", systemImage: "doc.on.doc") { UIPasteboard.general.string = message.text }
            Button(message.speaker == .me ? "编辑后再说" : "引用到回复", systemImage: "square.and.pencil") {
                conversation.log.draft = message.text; editing = true
            }.disabled(!cleanDraft.isEmpty)
        } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel("这条消息的更多操作")
    }
    private var conversationComposer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let message = conversation.log.messages.last(where: { $0.playbackID == app.injection.playback.id && $0.speaker == .me }), message.playbackID != nil {
                PlaybackProgressView(snapshot: app.injection.playback, identifier: "playback.face.pinned")
            }
            if !editing {
            HStack(spacing: 12) {
                if !silent {
                Button {
                    editing = false
                    if conversation.listening.requested || app.speech.isRecording { conversation.pause() }
                    else { conversation.startListening() }
                } label: {
                    Label(conversation.requesting ? "检查权限中" : app.speech.isRecording || conversation.listening.requested ? "暂停听" : conversation.log.messages.isEmpty ? "开始听" : "继续听",
                          systemImage: app.speech.isRecording || conversation.listening.requested ? "pause.fill" : "mic.fill")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
                        .background(Color.ylctMint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                }.foregroundStyle(Color.ylctMint).disabled(conversation.requesting || busy || app.injection.callActive)
                    .accessibilityIdentifier("conversation.listen")
                }
                if busy {
                    Button { conversation.stopAll() } label: {
                        Label("停止播报", systemImage: "stop.fill").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
                    }.foregroundStyle(Color.ylctDanger)
                } else {
                    Button {
                        conversation.stopAll(); conversation.setVisible(false); editing = false; showPartnerInput = true
                    } label: {
                        Label("请对方打字", systemImage: "person.crop.rectangle").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
                    }
                }
            }
            }
            if app.sessionPreference == .captions {
                Button("展开文字回复") { app.sessionPreference = .spokenReply }.frame(maxWidth: .infinity, minHeight: 44)
            } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("常用回复").font(.caption.weight(.semibold))
                    Text("· 离线可用").font(.caption2)
                    Spacer()
                    Button {
                        conversation.stopAll(); conversation.setVisible(false); showCustomPhrases = true
                    } label: {
                        Label("管理", systemImage: "slider.horizontal.3").font(.caption.weight(.semibold))
                            .frame(minWidth: 60, minHeight: 44)
                    }.accessibilityLabel("管理常用回复").accessibilityIdentifier("phrases.manage")
                }.foregroundStyle(Color.ylctTextSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(app.visibleShortcuts(including: quickReplies)) { shortcut in
                                let snapshot = app.injection.playback.sourceID == shortcut.id && conversation.log.messages.contains(where: { $0.playbackID == app.injection.playback.id }) ? app.injection.playback : nil
                                Button { editing = false; followsLatest = true; if silent { conversation.sendTextOnly(shortcut.text) } else { conversation.send(shortcut.text, shortcutID: shortcut.id) } } label: {
                                    Text(shortcut.text).font(.subheadline).padding(.horizontal, 12).frame(minHeight: 44)
                                        .playbackFill(snapshot, radius: 22)
                                        .ylctGlass(Capsule(), tint: shortcut.custom != nil ? .ylctBlue.opacity(0.12) : nil, touch: true)
                                }.disabled(!silent && (busy || app.injection.callActive || (shortcut.custom.map { !app.customPhrases.ready($0) } ?? false)))
                                    .accessibilityIdentifier("phrases.face.\(shortcut.id)")
                                    .playbackAccessibilityValue(snapshot)
                            }
                        }.ylctGroup()
                    }.frame(height: max(48, replyStripHeight)).accessibilityIdentifier("conversation.quick-reply-scroll").padding(.top, 4)
            }.tint(.ylctBlue).accessibilityElement(children: .contain)
                .accessibilityIdentifier("conversation.quick-replies")
            HStack(alignment: .bottom, spacing: 10) {
                TextField(silent ? "写给对方看…" : "输入回复，让对方听见…", text: draft, axis: .vertical)
                    .lineLimit(1...(typeSize.isAccessibilitySize ? 2 : 4)).font(.body).padding(13).foregroundStyle(Color.ylctText)
                    .background(Color.ylctField, in: RoundedRectangle(cornerRadius: 15)).focused($editing)
                    .accessibilityLabel("输入回复").accessibilityIdentifier("conversation.draft")
                Button { let text = cleanDraft; editing = false; followsLatest = true; if silent { conversation.sendTextOnly(text, clearDraft: true) } else { conversation.send(text, clearDraft: true) } } label: {
                    VStack(spacing: 3) { Image(systemName: silent ? "arrow.up" : "speaker.wave.2.fill"); Text(silent ? "发送" : "播报").font(.caption.weight(.semibold)) }
                        .foregroundStyle(.white).frame(width: 60, height: 56).ylctLens(15, tint: .ylctAction, solid: .ylctAction, touch: true)
                }.disabled(cleanDraft.isEmpty || (!silent && (busy || app.injection.callActive))).opacity(cleanDraft.isEmpty || busy ? 0.45 : 1)
                    .accessibilityLabel(silent ? "发送文字" : "发送并播报回复").accessibilityIdentifier("conversation.send")
            }
            if !cleanDraft.isEmpty {
                Button { display(cleanDraft) } label: { Label("不出声，放大给对方看", systemImage: "textformat.size").font(.subheadline).frame(minHeight: 44) }
            } else {
                Text(silent ? "本次用文字交流" : conversation.listening.requested ? "播报时暂停听，播完继续 · 请确认对方听清" : "打字用系统语音 · 自带回复已内置，点按即播")
                    .font(.caption2).foregroundStyle(Color.ylctTextSecondary)
            }
            }
        }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 10).ylctDock()
    }
    private func display(_ text: String) {
        editing = false
        conversation.stopAll()
        conversation.setVisible(false)
        presentedMessage = PresentedMessage(text: text)
    }
}

private struct PartnerInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @FocusState private var editing: Bool
    let send: (String) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("请直接打字回复我", systemImage: "keyboard").font(.title2.bold()).foregroundStyle(Color.ylctText)
                    Text("写好后点「交给我」，我就能看到你的回复。点返回会暂存还没写完的文字。")
                        .font(.body).foregroundStyle(Color.ylctTextSecondary)
                    TextField("请输入你想说的话…", text: $text, axis: .vertical).lineLimit(4...10).font(.title3)
                        .padding(18).background(Color.ylctSurface, in: RoundedRectangle(cornerRadius: 20)).focused($editing)
                        .accessibilityIdentifier("conversation.partner-draft")
                    PrimaryButton(title: "交给我", systemImage: "checkmark.bubble") { send(text); dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding(24)
            }.background(YLCTBackground()).navigationTitle("文字沟通").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("返回") { dismiss() } } }
                .interactiveDismissDisabled(!text.isEmpty)
        }.tint(.ylctBlue)
    }
}
