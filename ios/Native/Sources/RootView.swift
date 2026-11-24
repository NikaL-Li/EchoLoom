import SwiftUI

struct RootView: View {
    @StateObject private var app = AppState()
    @AppStorage("ylct.native.onboarded") private var onboarded = false
    @AppStorage("ylct.appearance") private var appearance = "system"
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPermissions = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            YLCTBackground()
            // Keep the actual scroll view alive across tab visits. Its offset, photo and
            // folded layout are already correct on the very first frame back.
            HomeView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if app.tab == .home, let toast = app.toast {
                        toastView(toast).padding(.horizontal, 20).padding(.vertical, 6)
                    }
                }
                .opacity(app.tab == .home ? 1 : 0)
                .allowsHitTesting(app.tab == .home)
                .accessibilityHidden(app.tab != .home)
            if app.tab != .home {
                Group {
                    switch app.tab {
                    case .home: EmptyView()
                    case .scenes: EverydayScenesView()
                    case .phrases: PhraseLibraryView()
                    case .account: AccountView()
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 8) {
                        if let toast = app.toast { toastView(toast) }
                        GlassTabBar(selection: $app.tab)
                    }.padding(.horizontal, 20).padding(.vertical, 6)
                }
            }
        }
        .environmentObject(app)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .task {
            if UserDefaults.standard.object(forKey: "ylct.appearance") == nil,
               UserDefaults.standard.object(forKey: "ylct.followSystemAppearance") as? Bool == false { appearance = "dark" }
            #if DEBUG && targetEnvironment(simulator)
            // Only reset the guide flag on the simulator; never reset user data.
            if CommandLine.arguments.contains("--test-first-launch") {
                UserDefaults.standard.removeObject(forKey: "ylct.native.onboarded")
                onboarded = false
            }
            // Deterministic entry points for screenshot review; no seeded or saved data.
            if let index = CommandLine.arguments.firstIndex(of: "--review-screen"), CommandLine.arguments.indices.contains(index + 1) {
                switch CommandLine.arguments[index + 1] {
                case "account": app.tab = .account
                case "records": app.tab = .account
                case "scenes": app.tab = .scenes
                case "phrases": app.tab = .phrases
                case "login": app.tab = .account; app.showLogin = true
                case "delivery": app.openAddress()
                case "pickup": app.openPickup()
                case "dialogue": app.openDialogue(entry: CommandLine.arguments.contains("--review-listen") ? .faceToFace : .quickSpeech)
                case "permissions": showPermissions = true
                case "onboarding": showOnboarding = true
                case "sign": app.openSign()
                default: break
                }
            } else if !onboarded { showOnboarding = true }
            #else
            if !onboarded { showOnboarding = true }
            #endif
            app.injection.systemSpeechRate = Float(app.universal.data.preferences.systemSpeechRate)
            await app.bootstrap()
        }
        .onChange(of: app.universal.data.preferences.systemSpeechRate) { _, rate in app.injection.systemSpeechRate = Float(rate) }
        .onChange(of: app.universal.data.preferences.haptics) { _, enabled in app.conversation.hapticsEnabled = enabled }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { app.refreshOnForeground(); app.opening.returnedToApp() }
            if phase == .background {
                app.conversation.setForeground(false)
                app.speech.stop()
                if app.conversation.isFaceToFace { app.injection.stopSpeaking() }
            }
            if phase == .active { app.conversation.setForeground(true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in app.refreshRecordSummary() }
        .sheet(isPresented: $app.showAddress, onDismiss: app.formDidDismiss) { AddressSheet().environmentObject(app) }
        .sheet(isPresented: $app.showPickup, onDismiss: app.formDidDismiss) { PickupSheet().environmentObject(app) }
        .sheet(isPresented: $app.showDialogue, onDismiss: app.dialogueDidDismiss) { DialogueView().environmentObject(app) }
        .sheet(isPresented: $showPermissions) { PermissionsView().environmentObject(app) }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                onboarded = true
                showOnboarding = false
            }.environmentObject(app)
        }
        .fullScreenCover(isPresented: $app.showSign) { SignView().environmentObject(app) }
        .environment(\.playbackClock, app.injection.playbackClock)
    }
    private func toastView(_ toast: String) -> some View {
        Text(toast).font(.subheadline.weight(.medium)).foregroundStyle(.white)
            .multilineTextAlignment(.center).padding(.horizontal, 18).padding(.vertical, 12)
            .ylctLens(18, tint: .ylctNavy, solid: .ylctNavy)
            .accessibilityAddTraits(.updatesFrequently)
            .task(id: toast) {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                if app.toast == toast { app.toast = nil }
            }
    }

}

struct GlassTabBar: View {
    @Binding var selection: YLCTTab
    @Namespace private var tabs
    @Environment(\.accessibilityReduceMotion) private var still
    var body: some View {
        HStack(spacing: 5) {
            ForEach(YLCTTab.allCases) { tab in
                Button { selection = tab } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon).font(.body.weight(.semibold))
                        Text(tab.rawValue).font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(selection == tab ? Color.ylctBlue : Color.ylctTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background { if selection == tab { Capsule().fill(Color.ylctBlue.opacity(0.18)).matchedGeometryEffect(id: "selection", in: tabs) } }
                    .contentShape(Capsule())
                }
                .buttonStyle(PressStyle())
                .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
                .accessibilityIdentifier("tab.\(tab.id)")
            }
        }.padding(6).ylctGlass(Capsule()).animation(still ? nil : .easeOut(duration: 0.22), value: selection)
    }
}
