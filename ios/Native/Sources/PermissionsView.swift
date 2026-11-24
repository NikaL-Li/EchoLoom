import SwiftUI
import AVFAudio
import Speech
import CoreLocation
import UIKit

struct PermissionsView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var requesting = false
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "hand.raised.circle.fill").font(.system(size: 44)).foregroundStyle(Color.ylctBlue)
                        Text("用到时，再开启").font(.title.bold()).foregroundStyle(Color.ylctText)
                        Text("你决定开放哪些权限。现在跳过，也能使用常用语和大字牌。")
                            .font(.body).foregroundStyle(Color.ylctTextSecondary)
                    }.padding(.top, 8)
                    VStack(spacing: 18) {
                        permissionRow(icon: "mic.fill", title: "麦克风", detail: "面对面沟通时，接收现场声音。", allowed: app.speech.microphoneAuthorized, denied: AVAudioApplication.shared.recordPermission == .denied) {
                            Task {
                                requesting = true
                                _ = await AVAudioApplication.requestRecordPermission()
                                app.speech.refreshStatus()
                                requesting = false
                            }
                        }
                        Divider()
                        permissionRow(icon: "waveform", title: "语音识别", detail: "把现场语音转成文字；可能需要网络。", allowed: app.speech.speechAuthorized, denied: SFSpeechRecognizer.authorizationStatus() == .denied || SFSpeechRecognizer.authorizationStatus() == .restricted) {
                            requesting = true
                            SFSpeechRecognizer.requestAuthorization { _ in
                                Task { @MainActor in app.speech.refreshStatus(); requesting = false }
                            }
                        }
                    }.ylctCard(padding: 18)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("电话里替你说", systemImage: "phone.badge.waveform").font(.headline).foregroundStyle(Color.ylctText)
                        Text("使用通话播报前，请打开系统「通话中添加音频」，再在 App 中开启。它不能转写对方的电话声音。")
                            .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                        Button("打开通话音频设置") { app.injection.openAccessibilitySettings() }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctBlue).frame(minHeight: 44)
                    }.ylctCard(padding: 18)
                }.padding(20)
            }.background(YLCTBackground())
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(title: "完成") { finish() }
                        .accessibilityIdentifier("permissions.done")
                        .padding(16).ylctDock()
                }
                .navigationTitle("权限管理").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("关闭") { finish() } } }
        }.tint(.ylctBlue)
            .onAppear { app.speech.refreshStatus() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { app.speech.refreshStatus() } }
    }
    private func permissionRow(icon: String, title: String, detail: String, allowed: Bool, denied: Bool, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundStyle(Color.ylctBlue).frame(width: 24)
                Text(title).font(.headline).foregroundStyle(Color.ylctText)
                Spacer()
                if allowed {
                    Label("已完成", systemImage: "checkmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(Color.ylctMint)
                } else {
                    Button(denied ? "去设置" : "允许") {
                        if denied { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                        else { action() }
                    }.font(.subheadline.weight(.semibold)).frame(minWidth: 64, minHeight: 44)
                        .background(Color.ylctBlue.opacity(0.08), in: Capsule()).disabled(requesting)
                }
            }
            Text(detail).font(.subheadline).foregroundStyle(Color.ylctTextSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }
    private func finish() { dismiss() }
}
