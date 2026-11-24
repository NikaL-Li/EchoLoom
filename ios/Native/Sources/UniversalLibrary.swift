import SwiftUI

struct CommunicationPreferencesView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("面对面默认模式") {
                    ForEach(CommunicationPreference.allCases) { choice in
                        Button {
                            app.universal.updatePreferences { $0.communication = choice }
                        } label: {
                            HStack {
                                Image(systemName: choice.icon).foregroundStyle(Color.ylctBlue)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(choice.title + (choice == .spokenReply ? " · 推荐" : "")).foregroundStyle(Color.ylctText)
                                    Text(choice.detail).font(.caption).foregroundStyle(Color.ylctTextSecondary)
                                }
                                Spacer()
                                if app.universal.data.preferences.communication == choice { Image(systemName: "checkmark") }
                            }.padding(.vertical, 5)
                        }.accessibilityIdentifier("preference.\(choice.rawValue)")
                    }
                }.listRowBackground(YLCTReadingPlate())
                Section("播报") {
                    Picker("声音", selection: Binding(get: { app.injection.voiceGender }, set: app.injection.setVoice)) {
                        Text("女声").tag("female"); Text("男声").tag("male")
                    }
                    Picker("临时打字语速", selection: Binding(get: { app.universal.data.preferences.systemSpeechRate }, set: { rate in app.universal.updatePreferences { $0.systemSpeechRate = rate } })) {
                        Text("慢").tag(0.38); Text("标准").tag(0.48); Text("快").tag(0.58)
                    }
                    Toggle("转写与播报结束时震动", isOn: Binding(get: { app.universal.data.preferences.haptics }, set: { enabled in app.universal.updatePreferences { $0.haptics = enabled } }))
                }.listRowBackground(YLCTReadingPlate())
                UniversalStoreNotice()
            }.ylctListCanvas().navigationTitle("沟通偏好").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("完成") { dismiss() } }
        }
    }
}

struct PhraseLibraryView: View {
    @EnvironmentObject private var app: AppState
    @State private var filter = "全部"
    @State private var manage = false
    @State private var order = false
    @State private var playing: String?
    private let categories = ["沟通", "办事", "生活"]
    private func category(_ item: PhraseShortcut) -> String {
        app.universal.data.phraseCategories[item.id] ?? (item.custom != nil ? "自定义" : PhraseShortcut.riderTexts.contains(item.text) ? "骑手" : "沟通")
    }
    private var entries: [PhraseShortcut] {
        app.customPhrases.shortcuts(including: app.visibleBuiltIns).filter {
            filter == "全部" || (filter == "收藏" ? app.universal.data.favoritePhraseIDs.contains($0.id) : category($0) == filter)
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["全部","收藏"] + categories + ["自定义"] + (app.universal.data.preferences.riderScenes ? ["骑手"] : []), id: \.self) { option in
                                Button { filter = option } label: {
                                    Text(option).font(.subheadline.weight(.medium)).padding(.horizontal, 12).frame(minHeight: 44)
                                        .foregroundStyle(option == filter ? Color.white : Color.ylctText)
                                        .ylctGlass(Capsule(), tint: option == filter ? .ylctAction : nil, solid: option == filter ? .ylctAction : .ylctSurface, touch: true)
                                }.buttonStyle(.plain).accessibilityAddTraits(option == filter ? [.isSelected] : [])
                            }
                        }
                    }.ylctGroup()
                }.listRowBackground(Color.clear)
                if entries.isEmpty { Text(filter == "收藏" ? "点句子旁的星标，便能在这里找到。" : "这个分类里还没有常用语。").foregroundStyle(.secondary) }
                ForEach(entries) { item in
                    let snapshot = playing == item.id ? app.injection.playback : nil
                    HStack {
                        Button {
                            if playing == item.id && app.injection.playback.phase.isBusy { app.injection.stopSpeaking() }
                            else { playing = item.id; app.speak(item.text, sourceID: item.id) }
                        } label: {
                            HStack {
                                Image(systemName: snapshot?.phase.isBusy == true ? "stop.fill" : "speaker.wave.2")
                                Text(item.text).foregroundStyle(Color.ylctText).multilineTextAlignment(.leading)
                                Spacer()
                            }.padding(10).frame(minHeight: 44).playbackFill(snapshot, radius: 10)
                        }.buttonStyle(.borderless).playbackAccessibilityValue(snapshot)
                        Button { app.universal.togglePhraseFavorite(item.id) } label: {
                            Image(systemName: app.universal.data.favoritePhraseIDs.contains(item.id) ? "star.fill" : "star").frame(minWidth: 38, minHeight: 44)
                        }.buttonStyle(.borderless).accessibilityLabel("收藏或取消收藏" + item.text)
                        Menu {
                            ForEach(categories, id: \.self) { c in Button(c) { app.universal.setCategory(c, for: item.id) } }
                            Button("恢复默认分类") { app.universal.setCategory("", for: item.id) }
                        } label: { Image(systemName: "tag").frame(minWidth: 34, minHeight: 44) }.accessibilityLabel("分类：" + category(item))
                    }
                }.listRowBackground(YLCTReadingPlate())
                UniversalStoreNotice()
            }.ylctListCanvas().navigationTitle("常用语").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("排序") { app.injection.stopSpeaking(); order = true } }
                    ToolbarItem(placement: .topBarTrailing) { Button("管理与添加") { playing = nil; app.injection.stopSpeaking(); manage = true }.accessibilityIdentifier("phrases.manage") }
                }
                .safeAreaInset(edge: .bottom) { if playing == app.injection.playback.sourceID && playing != nil { PlaybackProgressView(snapshot: app.injection.playback, identifier: "library.progress").padding().ylctDock() } }
                .sheet(isPresented: $manage) { CustomPhrasesView() }
                .sheet(isPresented: $order) { PhraseOrderView(library: app.customPhrases) }
                .onDisappear { app.injection.stopSpeaking() }
        }
    }
}

struct SavedConversationsView: View {
    @EnvironmentObject private var app: AppState
    @State private var query = ""
    @State private var pending: SavedConversation?
    private var matches: [SavedConversation] {
        app.universal.data.conversations.filter { query.trimmed.isEmpty || $0.searchableText.localizedCaseInsensitiveContains(query.trimmed) }
    }
    var body: some View {
        List {
            UniversalStoreNotice()
            if matches.isEmpty { Text(query.isEmpty ? "在面对面对话的更多菜单中点「保存本次对话」，就能在这里查看。" : "没有找到匹配的对话").foregroundStyle(.secondary) }
            ForEach(matches) { record in
                NavigationLink {
                    List(record.lines) { line in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(line.speaker + (line.transcribed ? " · 转写" : "")).font(.caption).foregroundStyle(.secondary)
                            Text(line.text).textSelection(.enabled)
                        }
                    }.ylctListCanvas().navigationTitle(record.title)
                } label: {
                    VStack(alignment: .leading) { Text(record.title); Text(record.savedAt, style: .date).font(.caption).foregroundStyle(.secondary); Text(record.lines.last?.text ?? "").font(.subheadline).lineLimit(1) }
                }.swipeActions { Button("删除", role: .destructive) { pending = record } }
            }
        }.ylctListCanvas().navigationTitle("保存的对话").searchable(text: $query, prompt: "搜索标题或内容")
            .alert("删除这段对话？", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
                Button("删除", role: .destructive) { if let pending { app.universal.deleteConversation(pending.id) } }
                Button("取消", role: .cancel) {}
            }
    }
}

struct AssistiveGuide: View {
    var body: some View {
        List {
            Section("实时字幕") { NavigationLink("通话时查看对方说的话") { LiveCaptionGuide() } }.listRowBackground(YLCTReadingPlate())
            Section("声音识别") { Text("在系统设置中搜索「声音识别」，开启后选择想关注的声音，例如门铃或敲门声。") }.listRowBackground(YLCTReadingPlate())
        }.ylctListCanvas().navigationTitle("系统辅助指引")
    }
}

struct PhoneToolsView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    @State private var confirm = false
    @State private var pickedName = ""
    @State private var pickedNumber = ""
    private var name: String { app.universal.openings.contact(number)?.name ?? (number == pickedNumber ? pickedName : "") }
    private var opening: String? { app.openingText(for: number) }
    private var confirmationMessage: String {
        guard app.universal.openings.automatic, let opening else { return number + "\n本次不会自动播报。" }
        let timing = app.injection.injectionEnabled ? "注入可用时，接通后等 \(app.universal.openings.delay) 秒播报。" : "当前通话注入未开启，本次不会自动播报。"
        return number + "\n接通后的开场白：" + opening + "\n" + timing
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("快捷拨号") {
                    ContactNumberButton { n, tel in number = tel; pickedName = n; pickedNumber = tel }
                    if !app.universal.openings.contacts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("常用联系人").font(.caption).foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(app.universal.openings.contacts) { c in
                                        Button { number = c.number } label: {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(c.name).font(.subheadline.weight(.semibold))
                                                Text(c.number).font(.caption.monospacedDigit())
                                            }.padding(.horizontal, 12).frame(minHeight: 48)
                                                .background(Color.ylctBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                        }.buttonStyle(.plain).accessibilityLabel(c.name + "，" + c.number)
                                    }
                                }
                            }
                        }
                    }
                    TextField("完整电话号码", text: $number).keyboardType(.phonePad)
                    if !name.isEmpty { Text(name).font(.subheadline).foregroundStyle(.secondary) }
                    if !number.isEmpty && CustomerPhone(universal: number) == nil { Text("请核对完整号码，境外号码须含国家区号。").font(.caption) }
                    Button("核对并拨打") { confirm = true }.disabled(CustomerPhone(universal: number) == nil)
                }.listRowBackground(YLCTReadingPlate())
                Section("本次开场") {
                    Text(opening ?? "原语音已移除，请重新选择开场白。")
                    Text(app.universal.openings.automatic ? "接通后等待 \(app.universal.openings.delay) 秒，注入可用才自动播报。" : "手动播报 · 自动开场未开启").font(.caption).foregroundStyle(.secondary)
                    if app.universal.openings.automatic && !app.injection.injectionEnabled {
                        Text("通话注入尚未开启，本机暂不能自动播报。").font(.footnote).foregroundStyle(Color.ylctOrange)
                        Button(app.injection.injectionState.needsSettings ? "打开通话音频设置" : "启用通话注入") {
                            if app.injection.injectionState.needsSettings { app.injection.openAccessibilitySettings() }
                            else { Task { await app.injection.requestAndEnable() } }
                        }
                    }
                    NavigationLink("设置开场白与常用联系人") { OpeningSettingsView() }
                    Button("在当前通话播报这句") { if let opening { app.opening.manual(opening) } }
                        .disabled(!app.opening.canPlayManually || opening == nil)
                    if app.injection.playback.sourceID == "call.opening" {
                        PlaybackProgressView(snapshot: app.injection.playback, identifier: "opening.progress")
                        if app.injection.playback.phase.isBusy { Button("停止播报") { app.injection.stopSpeaking() } }
                    }
                }.listRowBackground(YLCTReadingPlate())
                Section { NavigationLink("查看实时字幕开启方法") { LiveCaptionGuide() } }.listRowBackground(YLCTReadingPlate())
            }.ylctListCanvas().navigationTitle("拨打电话").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("完成") { dismiss() } }
                .onAppear { if number.isEmpty { number = app.lastToolsNumber } }
                .alert("拨给 " + (name.isEmpty ? number : name) + "？", isPresented: $confirm) {
                    Button("拨号") { if let phone = CustomerPhone(universal: number) { app.lastToolsNumber = phone.number; dismiss(); app.dialCustomer(phone, useOpening: true) } }
                    Button("取消", role: .cancel) {}
                } message: { Text(confirmationMessage) }
        }
    }
}
