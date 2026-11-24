import SwiftUI

struct CustomPhrasesView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showEditor = false
    @State private var editingPhrase: CustomPhrase?
    @State private var deletingPhrase: CustomPhrase?
    @State private var confirmDelete = false
    @State private var previewed = false
    @State private var showOrder = false
    @State private var pendingSuccess: String?
    @State private var successMessage: String?
    private var library: CustomPhraseLibrary { app.customPhrases }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("常说的话，提前准备好").font(.title2.bold()).foregroundStyle(Color.ylctText)
                        Text("添加一次，保存男、女两种声音。以后跟随你的声音选择，点一下就能离线说。")
                            .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    }
                    if let error = library.loadError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error).foregroundStyle(Color.ylctDanger)
                            Button("重新读取") { library.reload() }.frame(minHeight: 44)
                        }.ylctCard()
                    }
                    if library.phrases.isEmpty, library.loadError == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "waveform.badge.plus").font(.largeTitle).foregroundStyle(Color.ylctBlue)
                            Text("把你的习惯用语存下来").font(.headline)
                            Text("例如问路、请对方发短信，或你常用的礼貌回复。系统自带的常用语会继续保留。")
                                .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).ylctCard()
                    }
                    ForEach(library.phrases) { phrase in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(phrase.text).font(.headline).foregroundStyle(Color.ylctText).textSelection(.enabled)
                                .accessibilityIdentifier("phrases.text.\(phrase.id.uuidString)")
                            Label(library.ready(phrase) ? "男、女声已保存 · 离线可用" : "文件缺失，请重新生成", systemImage: library.ready(phrase) ? "checkmark.circle.fill" : "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(library.ready(phrase) ? Color.ylctMint : Color.ylctDanger)
                            HStack(spacing: 12) {
                                previewButton(phrase, voice: .female)
                                previewButton(phrase, voice: .male)
                            }
                            HStack {
                                Button(library.ready(phrase) ? "修改文字" : "重新生成") { openEditor(phrase) }.frame(minHeight: 44)
                                Spacer()
                                Button("删除", role: .destructive) { deletingPhrase = phrase; confirmDelete = true }.frame(minWidth: 44, minHeight: 44)
                            }.font(.subheadline.weight(.semibold))
                        }.ylctCard(padding: 16)
                    }
                    Text("常用语与音频保存在这台手机中，重新打开 App 仍可用；卸载 App 会移除。首次生成需要联网，试听不会改变你选择的默认声音。")
                        .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                    if app.injection.callActive {
                        Label("正在通话，试听可能被对方听到。", systemImage: "phone.fill")
                            .font(.subheadline).foregroundStyle(Color.ylctOrange)
                    }
                }.padding(20)
            }.background(YLCTBackground())
                .safeAreaInset(edge: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        if previewed {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(app.injection.voiceStatus)
                                        .font(.caption.weight(.semibold)).accessibilityIdentifier("phrases.playback")
                                    PlaybackProgressView(snapshot: app.injection.playback, identifier: "playback.preview.pinned")
                                }
                                if app.injection.playback.phase.isBusy {
                                    Button { app.injection.stopSpeaking() } label: { Image(systemName: "stop.fill").frame(width: 44, height: 44) }
                                        .foregroundStyle(Color.ylctDanger).accessibilityLabel("停止试听")
                                }
                            }
                            if !app.injection.outputNotice.isEmpty { Text(app.injection.outputNotice).font(.caption).foregroundStyle(Color.ylctDanger) }
                        }
                        PrimaryButton(title: "添加常用语", systemImage: "plus") { openEditor(nil) }
                            .disabled(library.loadError != nil).accessibilityIdentifier("phrases.add")
                    }.padding(16).ylctDock()
                }
                .navigationTitle("我的常用语").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("完成") { dismiss() }.accessibilityIdentifier("phrases.done") }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("全部排序") { app.conversation.stopAll(); showOrder = true }
                            .disabled(library.loadError != nil).accessibilityIdentifier("phrases.sort")
                    }
                }
                .sheet(isPresented: $showEditor, onDismiss: {
                    if let message = pendingSuccess { successMessage = message; pendingSuccess = nil }
                }) {
                    CustomPhraseEditor(phrase: editingPhrase) {
                        pendingSuccess = editingPhrase == nil ? "添加成功" : "修改成功"
                    }.environmentObject(app)
                }
                .sheet(isPresented: $showOrder) { PhraseOrderView(library: library) }
                .alert("删除这句常用语？", isPresented: $confirmDelete, presenting: deletingPhrase) { phrase in
                    Button("删除", role: .destructive) { app.injection.stopSpeaking(); library.delete(phrase) }
                    Button("取消", role: .cancel) {}
                } message: { phrase in Text("\(phrase.text)\n会同时移除本机的男、女声文件。") }
                .overlay(alignment: .top) {
                    if let successMessage {
                        Label("\(successMessage) · 男女声已保存", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctMint)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(.regularMaterial, in: Capsule()).padding(.top, 8)
                            .accessibilityIdentifier("phrases.saved-toast").allowsHitTesting(false)
                    }
                }
                .task(id: successMessage) {
                    guard successMessage != nil else { return }
                    do { try await Task.sleep(for: .seconds(3)) } catch { return }
                    successMessage = nil
                }
        }.tint(.ylctBlue).onDisappear { app.injection.stopSpeaking() }
    }
    private func openEditor(_ phrase: CustomPhrase?) {
        app.injection.stopSpeaking(); previewed = false; successMessage = nil; pendingSuccess = nil
        library.prepareEditor(); editingPhrase = phrase; showEditor = true
    }
    private func previewButton(_ phrase: CustomPhrase, voice: PhraseVoice) -> some View {
        let sourceID = "preview.\(phrase.id.uuidString).\(voice.rawValue)"
        let snapshot = app.injection.playback.sourceID == sourceID ? app.injection.playback : nil
        return Button {
            if snapshot?.phase.isBusy == true { app.injection.stopSpeaking() }
            else {
                app.conversation.stopAll(); previewed = true
                app.injection.speak(phrase.text, voiceOverride: voice.rawValue, sourceID: sourceID)
            }
        } label: {
            Label("试听\(voice.label)", systemImage: snapshot?.phase.isBusy == true ? "stop.fill" : "speaker.wave.2.fill")
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 10).frame(maxWidth: .infinity, minHeight: 46)
                .playbackFill(snapshot, radius: 12)
                .background(Color.ylctBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }.disabled(!library.ready(phrase)).buttonStyle(PressStyle())
            .accessibilityLabel("试听\(voice.label)")
            .playbackAccessibilityValue(snapshot)
            .accessibilityHint(snapshot?.phase.isBusy == true ? "再次点按停止试听" : "播放保存的\(voice.label)")
    }
}

struct PhraseOrderView: View {
    @EnvironmentObject private var app: AppState
    private var visible: [PhraseShortcut] {
        library.sortableShortcuts.filter { $0.custom != nil || app.visibleBuiltIns.contains($0.text) }
    }
    @ObservedObject var library: CustomPhraseLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var listRevision = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("系统预设和自定义，一起排序").font(.headline).foregroundStyle(Color.ylctText)
                    Text("拖动右侧把手，松手后自动保存。电话和面对面会按此顺序显示各自适用的话。")
                        .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    if let error = library.orderError {
                        Text(error).font(.caption).foregroundStyle(Color.ylctDanger).accessibilityIdentifier("phrases.order-error")
                        Button("重新读取") { library.reload(); listRevision += 1 }.frame(minHeight: 44)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                List {
                    ForEach(visible) { shortcut in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(shortcut.text).font(.body).foregroundStyle(Color.ylctText).lineLimit(2)
                            Text(shortcut.custom != nil ? "我的常用语" : PhraseShortcut.faceTexts.contains(shortcut.text) ? "通用常用语" : "骑手场景")
                                .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                        }.padding(.vertical, 4).accessibilityElement(children: .combine)
                            .accessibilityIdentifier("phrases.order.\(shortcut.id)")
                    }.onMove { offsets, destination in
                        var moved = visible.map(\.id)
                        let visibleIDs = Set(moved)
                        moved.move(fromOffsets: offsets, toOffset: destination)
                        var reordered = moved.makeIterator()
                        let ids = library.sortableShortcuts.map { item in
                            visibleIDs.contains(item.id) ? reordered.next()! : item.id
                        }
                        if !library.reorder(ids) { listRevision += 1 }
                    }
                }.listStyle(.insetGrouped).scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active)).id(listRevision)
            }.background(YLCTBackground())
                .navigationTitle("常用语排序").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() }.accessibilityIdentifier("phrases.sort-done") } }
        }.tint(.ylctBlue)
    }
}

struct CustomPhraseEditor: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var editing: Bool
    let phrase: CustomPhrase?
    let onSaved: () -> Void
    let completedText: ((String) -> Void)?
    init(phrase: CustomPhrase?, completedText: ((String) -> Void)? = nil, onSaved: @escaping () -> Void) {
        self.completedText = completedText; self.phrase = phrase; self.onSaved = onSaved; _text = State(initialValue: phrase?.text ?? "")
    }
    private var library: CustomPhraseLibrary { app.customPhrases }
    private var clean: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    FieldBox(label: "想保存的话") {
                        TextField("写一句你经常需要说的话", text: $text, axis: .vertical).lineLimit(3...6)
                            .focused($editing).disabled(library.isGenerating).accessibilityIdentifier("phrases.editor-text")
                    }
                    Text("\(clean.count) / 200 字").font(.caption).foregroundStyle(clean.count > 200 ? Color.ylctDanger : Color.ylctTextSecondary)
                    VStack(alignment: .leading, spacing: 14) {
                        voiceProgress(.female, ready: library.femaleReady)
                        voiceProgress(.male, ready: library.maleReady)
                        Text("点添加后立即生成并保存男女声，不会自动播放。两种声音都保存成功才会提示添加成功。")
                            .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                    }.ylctCard(padding: 16)
                    if !library.progress.isEmpty {
                        HStack { if library.isGenerating { ProgressView() }; Text(library.progress) }
                            .font(.subheadline).accessibilityIdentifier("phrases.generation-status")
                    }
                    if let error = library.generationError {
                        Text(error).font(.subheadline).foregroundStyle(Color.ylctDanger).accessibilityIdentifier("phrases.generation-error")
                    }
                    Text("首次使用 MiMo 联网生成，会将这段文字发送到语音服务；保存后播放无需联网。修改文字会重新生成两种声音，成功后才替换旧文件。")
                        .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }.padding(20)
            }.scrollDismissesKeyboard(.interactively).background(YLCTBackground())
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 8) {
                        PrimaryButton(title: library.isGenerating ? "正在生成并保存…" : library.generationError != nil ? "重试添加" : phrase == nil ? "添加" : "保存修改", systemImage: "checkmark") {
                            editing = false
                            library.generate(text: text, replacing: phrase?.id) { completedText?(clean); onSaved(); dismiss() }
                        }.disabled(library.isGenerating || clean.isEmpty || clean.count > 200)
                            .accessibilityIdentifier("phrases.generate")
                        if library.isGenerating { Button("取消生成") { library.cancelGeneration() }.frame(minHeight: 44) }
                    }.padding(16).ylctDock()
                }
                .navigationTitle(phrase == nil ? "添加常用语" : "修改常用语").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("取消") { library.cancelGeneration(); dismiss() } }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { editing = false }.accessibilityIdentifier("phrases.dismiss-keyboard") }
                }
        }.tint(.ylctBlue).interactiveDismissDisabled(library.isGenerating)
            .onChange(of: text) { _, value in library.editorTextChanged(value) }
            .onDisappear { library.cancelGeneration() }
    }
    private func voiceProgress(_ voice: PhraseVoice, ready: Bool) -> some View {
        HStack {
            Label("\(voice.label) · \(voice.name)", systemImage: "waveform")
            Spacer()
            Label(ready ? "已生成" : "待生成", systemImage: ready ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(ready ? Color.ylctMint : Color.ylctTextSecondary)
        }.font(.subheadline)
    }
}
