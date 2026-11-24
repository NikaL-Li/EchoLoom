import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var app: AppState
    @State private var showPermissions = false
    @State private var showCustomPhrases = false
    @State private var showOnboarding = false
    @State private var preferences = false
    @AppStorage("ylct.appearance") private var appearance = "system"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    communication
                    general
                    broadcast
                    privacy
                    UniversalStoreNotice()
                    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                        Text("译声 " + version).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .ylctGroup()
                .frame(maxWidth: 600)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .background(YLCTBackground())
            .navigationTitle("我的").navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $preferences) { CommunicationPreferencesView() }
            .sheet(isPresented: $showCustomPhrases) { CustomPhrasesView() }
            .sheet(isPresented: $showPermissions) { PermissionsView() }
            .fullScreenCover(isPresented: $showOnboarding) { OnboardingView(isReplay: true) { showOnboarding = false } }
        }
    }

    private var communication: some View {
        AccountSection("沟通设置") {
            Button { preferences = true } label: {
                AccountRow("沟通偏好", "slider.horizontal.3", value: app.universal.data.preferences.communication.title)
            }
            .accessibilityLabel("沟通偏好").accessibilityValue(app.universal.data.preferences.communication.title)
            rowDivider
            NavigationLink { OpeningSettingsView() } label: { AccountRow("通话开场与常用联系人", "phone") }
            rowDivider
            Button { showCustomPhrases = true } label: { AccountRow("我的常用语", "quote.bubble") }
                .accessibilityIdentifier("phrases.manage")
            rowDivider
            NavigationLink { SavedConversationsView() } label: { AccountRow("保存的对话", "tray.full") }
        }
    }

    private var general: some View {
        AccountSection("使用与外观") {
            Button { showOnboarding = true } label: { AccountRow("重看使用引导", "book") }
                .accessibilityIdentifier("account.onboarding")
            rowDivider
            NavigationLink { AssistiveGuide() } label: { AccountRow("实时字幕与声音识别", "captions.bubble") }
            rowDivider
            Button { showPermissions = true } label: { AccountRow("权限管理", "hand.raised") }
            rowDivider
            Menu {
                Picker("外观", selection: $appearance) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
            } label: {
                AccountRow("外观", "circle.lefthalf.filled", value: appearanceName, accessory: "chevron.up.chevron.down")
            }
            .accessibilityLabel("外观").accessibilityValue(appearanceName)
            rowDivider
            Toggle(isOn: Binding(get: { app.universal.data.preferences.riderScenes }, set: { enabled in
                app.universal.updatePreferences { $0.riderScenes = enabled }
            })) { AccountLabel("显示骑手场景", "bicycle") }
                .frame(minHeight: 50).tint(.ylctTealAction).accessibilityIdentifier("account.rider")
        }
    }

    private var broadcast: some View {
        let state = app.injection.injectionState
        return AccountSection("通话播报") {
            VStack(alignment: .leading, spacing: 6) {
                Label(state.title, systemImage: state.symbol)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctText)
                Text(state.detail).font(.footnote).foregroundStyle(Color.ylctTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 14)
            Divider()
            Toggle(isOn: Binding(get: { app.injection.autoInjection }, set: { app.injection.setAutoInjection($0) })) {
                AccountLabel("启动时自动开启", "power")
            }.frame(minHeight: 50).tint(.ylctTealAction)
            rowDivider
            Button { Task { await app.toggleInjection() } } label: {
                AccountRow(app.injection.injectionEnabled ? "关闭播报注入" : "开启播报注入", "speaker.wave.2", accessory: nil)
            }
            rowDivider
            Button { app.injection.openAccessibilitySettings() } label: {
                AccountRow("系统设置", "gearshape", accessory: "arrow.up.forward")
            }
        }
    }

    private var privacy: some View {
        AccountSection("隐私") {
            Text("场景资料与对话只有在你选择保存时才会留在本机。场景可在场景列表删除，已保存的对话可左滑删除。应用不保存通话或现场录音。")
                .font(.footnote).foregroundStyle(Color.ylctTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 14)
        }
    }

    private var rowDivider: some View { Divider().padding(.leading, 38) }
    private var appearanceName: String {
        switch appearance { case "light": "浅色"; case "dark": "深色"; default: "跟随系统" }
    }
}

// One optical surface per group keeps the text, switches and separators on a common plane.
private struct AccountSection<Content: View>: View {
    let title: String
    let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctTextSecondary)
                .padding(.leading, 6).accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content }
                .padding(.horizontal, 16).frame(maxWidth: .infinity).ylctLens(22)
        }
    }
}

private struct AccountLabel: View {
    let title: String, icon: String
    init(_ title: String, _ icon: String) { self.title = title; self.icon = icon }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.body.weight(.medium))
                .foregroundStyle(Color.ylctBlue).frame(width: 26).accessibilityHidden(true)
            Text(title).font(.body).foregroundStyle(Color.ylctText)
        }
    }
}

private struct AccountRow: View {
    let title: String, icon: String, value: String?, accessory: String?
    init(_ title: String, _ icon: String, value: String? = nil, accessory: String? = "chevron.right") {
        self.title = title; self.icon = icon; self.value = value; self.accessory = accessory
    }
    var body: some View {
        HStack(spacing: 8) {
            AccountLabel(title, icon)
            Spacer(minLength: 4)
            if let value { Text(value).font(.subheadline).foregroundStyle(Color.ylctTextSecondary) }
            if let accessory {
                Image(systemName: accessory).font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ylctTextSecondary).accessibilityHidden(true)
            }
        }.frame(minHeight: 50).contentShape(Rectangle())
    }
}
