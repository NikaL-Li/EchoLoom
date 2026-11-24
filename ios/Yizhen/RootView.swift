import SwiftUI
import Foundation

struct RootView: View {
    @Environment(YZAppState.self) private var appState

    init() {}


    var body: some View {
        YZThemeRuntime.fontSize = appState.fontSize.points
        YZThemeRuntime.highContrast = appState.highContrast

        let revision = "\(appState.fontSize.rawValue)-\(appState.highContrast)"
        @Bindable var state = appState

        return ZStack {
            YZTheme.bg.ignoresSafeArea()

            tabPages
                .id(revision)
                .opacity(showsTabPages ? 1 : 0)
                .allowsHitTesting(appState.route == nil && !appState.emergencySign)
                .accessibilityHidden(appState.route != nil || appState.emergencySign)

            routeLayer
                .transition(.opacity)
                .zIndex(10)
        }
        .overlay(alignment: .bottom) {
            if showsTabBar {
                YZTabBar(
                    selection: Binding(
                        get: { appState.tab },
                        set: { appState.selectTab($0) }
                    )
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .frame(maxWidth: 458)
                .transition(.opacity)
                .zIndex(30)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: appState.tab)
        .animation(.easeInOut(duration: 0.12), value: appState.route)
        .animation(.easeInOut(duration: 0.12), value: appState.emergencySign)
        .preferredColorScheme(colorSchemeOverride)
        .statusBarHidden(appState.emergencySign)
        .onChange(of: appState.themeMode) { _, _ in saveSettings() }
        .onChange(of: appState.fontSize) { _, _ in saveSettings() }
        .onChange(of: appState.highContrast) { _, _ in saveSettings() }
        .onChange(of: appState.textOnly) { _, _ in saveSettings() }
    }

    private var tabPages: some View {
        ZStack {
            HomeView()
                .opacity(appState.tab == .home ? 1 : 0)
                .allowsHitTesting(appState.tab == .home)
                .accessibilityHidden(appState.tab != .home)

            RecordsView(
                sessions: appState.sessions,
                todaySessionCount: appState.todaySessionCount,
                totalSessionCount: appState.totalSavedCount,
                onSelectSession: { appState.openSession($0) },
                onRequestStartConversation: { appState.startTalk() }
            )
            .opacity(appState.tab == .records ? 1 : 0)
            .allowsHitTesting(appState.tab == .records)
            .accessibilityHidden(appState.tab != .records)

            profileTab
                .opacity(appState.tab == .profile ? 1 : 0)
                .allowsHitTesting(appState.tab == .profile)
                .accessibilityHidden(appState.tab != .profile)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var profileTab: some View {
        @Bindable var state = appState

        return ProfileView(
            appearance: $state.themeMode,
            fontSize: $state.fontSize,
            isHighContrastEnabled: $state.highContrast,
            isTextOnlyMode: $state.textOnly,
            phraseCountText: "\(appState.phraseCount) 条",
            versionText: versionText,
            onPhrasesTap: { appState.openPhrases() },
            onGuideTap: { appState.openGuide() }
        )
    }

    @ViewBuilder
    private var routeLayer: some View {
        if appState.emergencySign {
            SignView.emergency {
                appState.hideEmergencySign()
            }
        } else if let route = appState.route {
            routePage(route)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(YZTheme.bg)
        }
    }

    @ViewBuilder
    private func routePage(_ route: YZRoute) -> some View {
        switch route {
        case .talk(let faceToFace):
            TalkView(initialFaceToFace: faceToFace) {
                appState.closeTalk()
            }
            .id("talk-\(revisionKey)")

        case .phrases:
            PhrasesView(
                scene: appState.scene,
                initialSub: appState.subScene,
                store: appState.phraseStore,
                onBack: { appState.closeRoute() },
                onSend: { text, sub in appState.startTalk(withPhrase: text, subScene: sub) },
                onStoreChanged: { appState.reloadCustomPhrases() }
            )

        case .session(let id):
            if let session = appState.session(with: id) {
                SessionView(session: session) {
                    appState.closeRoute()
                }
            } else {
                missingSessionView
            }

        case .guide:
            GuideView {
                appState.closeRoute()
            }
        }
    }

    private var missingSessionView: some View {
        VStack(spacing: 12) {
            YZPillButton(title: "返回记录") {
                appState.closeRoute()
            }
            Text("这次记录不在了")
                .font(YZTheme.fontSectionTitle)
                .foregroundStyle(YZTheme.ink)
            Text("本机最多保留最近 20 次对话。")
                .font(YZTheme.fontCaption)
                .foregroundStyle(YZTheme.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(YZTheme.bg)
    }

    private var revisionKey: String {
        "\(appState.fontSize.rawValue)-\(appState.highContrast)"
    }

    private var isTalkRoute: Bool {
        if case .talk = appState.route { return true }
        return false
    }

    private var showsTabPages: Bool {
        !appState.emergencySign && !isTalkRoute
    }

    private var showsTabBar: Bool {
        !appState.emergencySign && !isTalkRoute
    }

    private var colorSchemeOverride: ColorScheme? {
        if appState.highContrast {
            return .light
        }

        switch appState.themeMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
        return "译诊 \(version)（\(build)）"
    }

    private func saveSettings() {
        YZProfileSettingsPersistence.save(from: appState)
    }
}

private struct YZTabBar: View {
    @Binding var selection: YZTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(YZTab.allCases, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(item.title)
                            .font(YZTheme.fontTab)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(YZPressButtonStyle())
                .foregroundStyle(
                    selection == item
                        ? (YZTheme.highContrast ? Color.white : YZTheme.blue)
                        : YZTheme.ink3
                )
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            selection == item
                                ? (YZTheme.highContrast ? Color.black : YZTheme.blueSoft)
                                : Color.clear
                        )
                )
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item ? [.isSelected] : [])
            }
        }
        .padding(6)
        .frame(height: YZTheme.tabBarHeight)
        .background {
            if YZTheme.highContrast {
                Capsule().fill(YZTheme.card)
            } else {
                Capsule().fill(.ultraThinMaterial)
            }
        }
        .overlay(
            Capsule().stroke(
                YZTheme.line,
                lineWidth: YZTheme.highContrast ? 2 : 1
            )
        )
        .shadow(
            color: YZTheme.highContrast ? .clear : Color.black.opacity(0.05),
            radius: 12,
            y: 2
        )
    }
}

#if DEBUG
#Preview {
    RootView()
        .environment(YZAppState.preview)
}
#endif
