import Foundation
import SwiftUI

extension YZTab {
    var title: String {
        switch self {
        case .home: "首页"
        case .records: "记录"
        case .profile: "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .records: "list.bullet.rectangle"
        case .profile: "person"
        }
    }
}

struct RootView: View {
    @Environment(YZAppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        ZStack {
            YZTheme.bg.ignoresSafeArea()

            tabPages
                .opacity(talkFaceToFace == nil ? 1 : 0)
                .allowsHitTesting(talkFaceToFace == nil)
                .accessibilityHidden(talkFaceToFace != nil)

            if appState.emergencySign {
                EmergencySignView(text: EmergencySignView.defaultText) {
                    appState.hideEmergencySign()
                }
                .transition(.opacity)
            } else if let faceToFace = talkFaceToFace {
                TalkShellView(faceToFace: faceToFace)
                    .transition(.opacity)
            } else if let route = appState.route {
                FeatureRouteView(route: route)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if showsTabBar {
                YZTabBar(selection: $appState.tab)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: appState.tab)
        .animation(.easeInOut(duration: 0.12), value: appState.route)
        .animation(.easeInOut(duration: 0.12), value: appState.emergencySign)
        .preferredColorScheme(colorSchemeOverride)
        .modifier(YZProfileSettingsPersistenceModifier(appState: appState))
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
                totalSessionCount: max(
                    YZFeatureSessionStore.savedTotalCount,
                    appState.sessions.count
                ),
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
        ProfileView(
            appearance: Binding(
                get: { appState.themeMode },
                set: { appState.themeMode = $0 }
            ),
            fontSize: Binding(
                get: { appState.fontSize },
                set: { appState.fontSize = $0 }
            ),
            isHighContrastEnabled: Binding(
                get: { appState.highContrast },
                set: { appState.highContrast = $0 }
            ),
            isTextOnlyMode: Binding(
                get: { appState.textOnly },
                set: { appState.textOnly = $0 }
            ),
            phraseCountText: "\(appState.phraseCount) 条",
            versionText: versionText,
            onPhrasesTap: { appState.openPhrases() },
            onGuideTap: { appState.openGuide() }
        )
    }

    private var versionText: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
        return "译诊 \(version)（\(build)）"
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

    private var talkFaceToFace: Bool? {
        if case .talk(let faceToFace) = appState.route {
            return faceToFace
        }
        return nil
    }

    private var showsTabBar: Bool {
        if appState.emergencySign {
            return false
        }
        return talkFaceToFace == nil
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
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == item ? YZTheme.blue : YZTheme.ink3)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(selection == item ? YZTheme.blueSoft : Color.clear)
                )
                .overlay {
                    if selection == item && YZTheme.highContrast {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black, lineWidth: 2)
                    }
                }
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item ? [.isSelected] : [])
            }
        }
        .padding(6)
        .frame(height: 64)
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

private struct TalkShellView: View {
    @Environment(YZAppState.self) private var appState
    let faceToFace: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ShellPillButton(title: "关闭") {
                    appState.closeTalk()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(faceToFace ? "面对面分屏" : "对话页")
                    .font(YZTheme.fontSectionTitle)
                    .foregroundStyle(YZTheme.ink)
                Text("这个页面正在接入中")
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 82)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(YZTheme.bg)
    }
}

private struct FeatureRouteView: View {
    @Environment(YZAppState.self) private var appState
    let route: YZRoute

    @ViewBuilder
    var body: some View {
        switch route {
        case .session(let id):
            if let session = appState.session(with: id) {
                SessionView(session: session) {
                    appState.closeRoute()
                }
            } else {
                RoutePageView(route: route)
            }
        case .guide:
            GuideView {
                appState.closeRoute()
            }
        default:
            RoutePageView(route: route)
        }
    }
}

private struct RoutePageView: View {
    @Environment(YZAppState.self) private var appState
    let route: YZRoute

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ShellPillButton(title: "返回") {
                    appState.closeRoute()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, YZTheme.pagePadding)
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(title)
                    .font(YZTheme.fontSectionTitle)
                    .foregroundStyle(YZTheme.ink)
                Text("这个页面正在接入中")
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, YZTheme.tabBottomInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(YZTheme.bg)
    }

    private var title: String {
        switch route {
        case .talk(let faceToFace):
            faceToFace ? "面对面分屏" : "对话页"
        case .phrases:
            "常用语"
        case .session:
            "会话详情"
        case .guide:
            "使用指南"
        }
    }
}

private struct ShellPillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(YZTheme.fontPill)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .foregroundStyle(YZTheme.blue)
                .background(YZTheme.card, in: Capsule())
                .overlay(
                    Capsule().stroke(
                        YZTheme.line,
                        lineWidth: YZTheme.highContrast ? 2 : 1
                    )
                )
                .shadow(color: YZTheme.shadowColor, radius: YZTheme.shadowRadius, y: YZTheme.shadowY)
        }
        .buttonStyle(ShellPillStyle())
        .accessibilityLabel(title)
    }
}

private struct ShellPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    RootView()
        .environment(YZAppState.preview)
}