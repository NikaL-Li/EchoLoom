import SwiftUI
import UIKit

private enum SceneRoute: Hashable { case template(EverydaySceneKind), saved(UUID) }

struct EverydayScenesView: View {
    @EnvironmentObject private var app: AppState
    @State private var deleting: EverydaySceneDraft?
    private var kinds: [EverydaySceneKind] {
        let favorites = app.universal.data.favoriteSceneKinds
        return favorites + EverydaySceneKind.allCases.filter { !favorites.contains($0) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PageIntro(title: "有准备，更安心", subtitle: "提前写下要问的话。资料会跟着你进入沟通，随时查看和引用。")
                    UniversalStoreNotice()
                    if !app.universal.data.scenes.isEmpty {
                        Text("保存的准备").font(.headline)
                        ForEach(app.universal.data.scenes) { scene in
                            HStack(spacing: 12) {
                                NavigationLink(value: SceneRoute.saved(scene.id)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: scene.kind.icon).foregroundStyle(Color.ylctBlue)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(scene.displayTitle).font(.headline)
                                            Text(scene.place.trimmed.isEmpty ? scene.kind.title : scene.place).font(.caption).foregroundStyle(Color.ylctTextSecondary)
                                        }
                                        Spacer()
                                    }.foregroundStyle(Color.ylctText).frame(minHeight: 54)
                                }.accessibilityIdentifier("scene.saved.\(scene.id)")
                                if !scene.navigationQuery.isEmpty {
                                    SceneRouteButton(scene: scene, compact: true)
                                }
                                Button { deleting = scene } label: { Image(systemName: "trash").frame(width: 44, height: 44) }
                                    .foregroundStyle(Color.ylctTextSecondary).accessibilityLabel("删除\(scene.displayTitle)")
                            }.ylctCard(padding: 14)
                        }
                    }
                    Text("选择一个场景").font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(kinds) { kind in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: kind.icon).font(.title2).foregroundStyle(Color.ylctBlue)
                                    Spacer()
                                    Button { _ = app.universal.toggleSceneFavorite(kind) } label: {
                                        Image(systemName: app.universal.data.favoriteSceneKinds.contains(kind) ? "star.fill" : "star").frame(width: 38, height: 44)
                                    }.accessibilityLabel(app.universal.data.favoriteSceneKinds.contains(kind) ? "取消收藏\(kind.title)" : "收藏\(kind.title)")
                                }
                                NavigationLink(value: SceneRoute.template(kind)) {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(kind.title).font(.headline)
                                        Text(kind.detail).font(.caption).foregroundStyle(Color.ylctTextSecondary).fixedSize(horizontal: false, vertical: true)
                                    }.frame(maxWidth: .infinity, minHeight: 58, alignment: .leading).contentShape(Rectangle())
                                }.foregroundStyle(Color.ylctText).accessibilityIdentifier("scene.kind.\(kind.rawValue)")
                            }.ylctCard(radius: 20, padding: 16)
                        }
                    }.ylctGroup()
                    if app.universal.data.preferences.riderScenes {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("骑手场景", systemImage: "bicycle").font(.headline)
                            HStack(spacing: 12) {
                                Button("送餐准备") { app.openAddress() }.frame(maxWidth: .infinity, minHeight: 44)
                                Button("取餐准备") { app.openPickup() }.frame(maxWidth: .infinity, minHeight: 44)
                            }.buttonStyle(.bordered)
                            NavigationLink("查看送达记录") { RecordsView() }.font(.subheadline)
                        }.ylctCard().accessibilityIdentifier("scene.rider")
                    }
                }.padding(20)
            }.background(YLCTBackground()).navigationTitle("场景").navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: SceneRoute.self) { route in
                    switch route {
                    case .template(let kind): EverydaySceneEditor(initial: EverydaySceneDraft(kind: kind))
                    case .saved(let id):
                        if let scene = app.universal.data.scenes.first(where: { $0.id == id }) {
                            EverydaySceneEditor(initial: scene)
                        } else {
                            ContentUnavailableView("找不到这份准备", systemImage: "doc")
                        }
                    }
                }
                .alert("删除这份准备？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                    Button("删除", role: .destructive) { if let deleting { _ = app.universal.deleteScene(deleting.id) }; deleting = nil }
                    Button("取消", role: .cancel) { deleting = nil }
                } message: { Text("只删除保存的场景资料，不会删除已保存的对话。") }
        }.tint(.ylctBlue)
    }
}

struct EverydaySceneEditor: View {
    @EnvironmentObject private var app: AppState
    @State private var draft: EverydaySceneDraft
    @State private var feedback: String?
    @FocusState private var editing: Bool
    init(initial: EverydaySceneDraft) { _draft = State(initialValue: initial) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageIntro(title: draft.kind.title + "前，准备一下", subtitle: "所有内容都可选。不填也能直接沟通；点保存后才会留在本机。")
                UniversalStoreNotice()
                VStack(alignment: .leading, spacing: 14) {
                    entry("这份准备的名字", placeholder: "例如：周五的预约", text: $draft.title, id: "scene.title")
                    Text("想说的话／想问的问题").font(.subheadline.weight(.semibold))
                    TextField(draft.kind.questionHint, text: $draft.questions, axis: .vertical).lineLimit(3...8)
                        .focused($editing).padding(13).background(Color.ylctField, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("scene.questions")
                    Text("一行写一件事，沟通时可逐条引用。").font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }.ylctCard()
                VStack(alignment: .leading, spacing: 14) {
                    Label("地点与联系", systemImage: "mappin.and.ellipse").font(.headline)
                    entry("地点", placeholder: "店名、机构或集合点", text: $draft.place, id: "scene.place")
                    entry("详细地址", placeholder: "导航前请核对地址", text: $draft.address, id: "scene.address")
                    entry("联系人", placeholder: "可选", text: $draft.contact, id: "scene.contact")
                    entry("电话", placeholder: "完整号码，或带国家区号", text: $draft.phone, id: "scene.phone")
                    SceneExternalActions(scene: draft)
                }.ylctCard()
                VStack(alignment: .leading, spacing: 14) {
                    entry("预约／订单／业务编号", placeholder: "仅在这次沟通中需要时填写", text: $draft.reference, id: "scene.reference")
                    entry("补充说明", placeholder: "你希望对方提前知道的事", text: $draft.notes, id: "scene.notes", multiline: true)
                    if draft.kind == .health {
                        Text("请和医护人员再次核对姓名、药名、剂量与时间；这里用于沟通准备。").font(.caption).foregroundStyle(Color.ylctTextSecondary)
                    }
                }.ylctCard()
            }.padding(20)
        }.scrollDismissesKeyboard(.interactively).background(YLCTBackground())
            .navigationTitle(draft.displayTitle).navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if let feedback {
                        Text(feedback).font(.subheadline).foregroundStyle(Color.ylctText)
                            .accessibilityIdentifier("scene.feedback")
                    }
                    PrimaryButton(title: "带上资料，开始沟通", systemImage: "bubble.left.and.bubble.right") {
                        editing = false; app.openSceneConversation(draft)
                    }.accessibilityIdentifier("scene.start")
                    Button("进入电话辅助") { editing = false; app.openSceneConversation(draft, phone: true) }
                        .font(.subheadline).frame(minHeight: 40).accessibilityIdentifier("scene.phone-mode")
                }.padding(16).ylctDock()
            }
            .onChange(of: draft) { _, _ in feedback = nil }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        editing = false
                        feedback = app.universal.saveScene(draft) ? "已保存，可在「场景」中再次打开" : app.universal.error
                    }.disabled(!draft.hasInformation || app.universal.loadFailed)
                        .accessibilityLabel("保存这份准备").accessibilityIdentifier("scene.save")
                }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("收起键盘") { editing = false }.accessibilityIdentifier("scene.dismiss-keyboard") } }
    }
    private func entry(_ label: String, placeholder: String, text: Binding<String>, id: String, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctText)
            TextField(placeholder, text: text, axis: .vertical).lineLimit(1...(multiline ? 5 : 3))
                .focused($editing).padding(13).background(Color.ylctField, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier(id)
        }
    }
}

struct SceneExternalActions: View {
    @EnvironmentObject private var app: AppState
    let scene: EverydaySceneDraft
    @State private var confirmCall = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                SceneRouteButton(scene: scene)
                Button { confirmCall = true } label: { Label("核对后拨号", systemImage: "phone").frame(maxWidth: .infinity, minHeight: 44) }
                    .disabled(scene.callablePhone == nil).accessibilityIdentifier("scene.call")
            }.buttonStyle(.bordered)
            if !scene.phone.trimmed.isEmpty, scene.callablePhone == nil {
                Text("号码不完整或格式无法识别，请核对；不会自动拨号。").font(.caption).foregroundStyle(Color.ylctOrange)
            }
        }
        .alert("核对联系电话", isPresented: $confirmCall) {
            if let phone = scene.callablePhone {
                Button("拨打 \(phone.number)") { app.dialCustomer(phone) }
                Button("复制号码") { UIPasteboard.general.string = phone.number }
            }
            Button("取消", role: .cancel) {}
        } message: { Text([scene.contact, scene.phone].filter { !$0.isEmpty }.joined(separator: "\n") + "\n将打开系统电话，不会自动播报。") }
        .alert("操作提示", isPresented: Binding(get: { app.externalActionMessage != nil }, set: { if !$0, app.externalActionMessage != nil { app.externalActionMessage = nil } })) {
            Button("知道了", role: .cancel) {}
        } message: { Text(app.externalActionMessage ?? "") }
    }
}

private struct SceneRouteButton: View {
    @EnvironmentObject private var app: AppState
    let scene: EverydaySceneDraft
    var compact = false
    @State private var mapNotice: String?
    @State private var confirmMap = false
    var body: some View {
        Button { confirmMap = true } label: {
            if compact { Label("路线", systemImage: "map").font(.caption.weight(.semibold)).fixedSize().frame(minWidth: 54, minHeight: 44) }
            else { Label("核对后导航", systemImage: "map").frame(maxWidth: .infinity, minHeight: 44) }
        }.disabled(scene.navigationQuery.isEmpty)
            .accessibilityLabel(compact ? "查看路线：" + scene.navigationQuery : "核对后导航")
            .accessibilityIdentifier(compact ? "scene.saved-route" : "scene.navigate")
        .confirmationDialog("确认目的地：\(scene.navigationQuery)", isPresented: $confirmMap, titleVisibility: .visible) {
            ForEach(NavigationTravelMode.allCases) { travel in
                Button("\(travel.label)导航") {
                    let modern: Bool
                    if #available(iOS 18.4, *) { modern = true } else { modern = false }
                    if let url = OrderNavigationLink.url(for: scene.navigationQuery, mode: travel, unified: modern) {
                        if compact {
                            app.openExternal(url, failure: "无法打开地图，请复制地址到地图中搜索。", reportsGlobally: false) { ok in
                                if !ok { mapNotice = "未打开地图，可再次点路线复制地址。" }
                            }
                        } else { app.openExternal(url, failure: "无法打开地图，请复制地址到地图中搜索。") }
                    }
                }
            }
            Button("复制地址") { UIPasteboard.general.string = scene.navigationQuery }
            Button("取消", role: .cancel) {}
        }
        .alert("地图提示", isPresented: Binding(get: { mapNotice != nil }, set: { if !$0 { mapNotice = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(mapNotice ?? "") }
    }
}

struct SceneContextSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let scene: EverydaySceneDraft
    let useText: (String) -> Void
    @State private var displayed: PresentedSceneText?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label(scene.kind.title, systemImage: scene.kind.icon).font(.subheadline).foregroundStyle(Color.ylctMint)
                    if !scene.displaySummary.isEmpty { Text(scene.displaySummary).font(.body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).ylctCard() }
                    if !scene.contact.isEmpty || !scene.phone.isEmpty { Text([scene.contact, scene.phone].filter { !$0.isEmpty }.joined(separator: " · ")).textSelection(.enabled) }
                    SceneExternalActions(scene: scene)
                    if !scene.usefulLines.isEmpty {
                        Text("点一句，带到回复框").font(.headline)
                        ForEach(Array(scene.usefulLines.enumerated()), id: \.offset) { _, line in
                            Button { useText(line); dismiss() } label: {
                                HStack { Text(line).multilineTextAlignment(.leading); Spacer(); Image(systemName: "arrow.turn.down.left") }
                                    .frame(maxWidth: .infinity, minHeight: 44).padding(12).background(Color.ylctSurfaceSoft, in: RoundedRectangle(cornerRadius: 12))
                            }.accessibilityIdentifier("scene.context-quote")
                        }
                    }
                    Button { displayed = PresentedSceneText(text: scene.displaySummary.isEmpty ? scene.displayTitle : scene.displaySummary) } label: {
                        Label("只展示资料，不出声", systemImage: "rectangle.and.text.magnifyingglass").frame(minHeight: 44)
                    }
                    Text("引用只填入文字，不会自动发送或播报。").font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }.padding(20)
            }.background(YLCTBackground()).navigationTitle(scene.displayTitle).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("返回沟通") { dismiss() } } }
                .fullScreenCover(item: $displayed) { text in MessageDisplayView(text: text.text) }
        }.tint(.ylctBlue)
    }
}
struct PresentedSceneText: Identifiable { let id = UUID(); let text: String }
struct PageIntro: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.title2.bold()).foregroundStyle(Color.ylctText)
            Text(subtitle).font(.subheadline).foregroundStyle(Color.ylctTextSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
struct UniversalStoreNotice: View {
    @EnvironmentObject private var app: AppState
    var body: some View {
        if let error = app.universal.error {
            VStack(alignment: .leading, spacing: 8) {
                Label(error, systemImage: "exclamationmark.circle").font(.subheadline).foregroundStyle(Color.ylctDanger)
                if app.universal.loadFailed { Button("重新读取") { app.universal.reload() }.frame(minHeight: 44) }
            }.accessibilityIdentifier("universal.store-error")
        }
    }
}
