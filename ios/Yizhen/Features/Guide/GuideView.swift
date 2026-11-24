import SwiftUI

struct GuideView: View {
    private let query: any YZGuidePermissionQuerying
    private let onBack: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    @State private var microphoneState: YZGuidePermissionRowState = .loading
    @State private var speechRecognitionState: YZGuidePermissionRowState = .loading
    @State private var microphoneHasResolved = false
    @State private var speechRecognitionHasResolved = false
    @State private var notice: String?
    @State private var openedSettingsFromNotDetermined = false

    init(onBack: @escaping () -> Void) {
        self.query = YZGuideSystemPermissionQuery()
        self.onBack = onBack
    }

    init(
        query: any YZGuidePermissionQuerying,
        onBack: @escaping () -> Void
    ) {
        self.query = query
        self.onBack = onBack
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
                backButton

                YZPageTitle(title: YZGuideCopy.pageTitle)

                ForEach(YZGuideCopy.steps) { step in
                    YZGuideStepCardView(step: step)
                }

                YZGuidePermissionCardView(
                    microphoneState: microphoneState,
                    speechRecognitionState: speechRecognitionState,
                    onOpenSettings: openSettings,
                    onRetry: refresh
                )

                if let notice {
                    Text(notice)
                        .font(YZGuideFont.caption)
                        .foregroundStyle(YZGuideStyle.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(YZGuideCopy.footer)
                    .font(YZGuideFont.tag)
                    .foregroundStyle(YZGuideStyle.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, YZTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, YZTheme.tabBottomInset)
            .yzContentWidth()
        }
        .scrollIndicators(.hidden)
        .background(YZGuideStyle.pageBackground)
        .onAppear {
            refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refresh()

            if openedSettingsFromNotDetermined {
                openedSettingsFromNotDetermined = false
                let hasNotDetermined = microphoneState.displayStatus == .notDetermined
                    || speechRecognitionState.displayStatus == .notDetermined
                if notice == nil && hasNotDetermined {
                    notice = YZGuideCopy.notDeterminedHint
                }
            }
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("返回")
            }
            .font(YZTheme.fontPill)
            .foregroundStyle(YZTheme.blue)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(YZTheme.card, in: Capsule())
            .overlay(
                Capsule().stroke(
                    YZTheme.line,
                    lineWidth: YZTheme.highContrast ? 2 : 1
                )
            )
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("返回")
    }

    private func refresh() {
        var failed = false

        let microphone = query.microphoneStatus()
        if case .failed = microphone {
            failed = true
            if !microphoneHasResolved {
                microphoneState = .failed
            }
        } else {
            microphoneState = microphone
            microphoneHasResolved = true
        }

        let speech = query.speechRecognitionStatus()
        if case .failed = speech {
            failed = true
            if !speechRecognitionHasResolved {
                speechRecognitionState = .failed
            }
        } else {
            speechRecognitionState = speech
            speechRecognitionHasResolved = true
        }

        notice = failed ? YZGuideCopy.permissionReadFailed : nil
    }

    private func openSettings() {
        if microphoneState.displayStatus == .notDetermined
            || speechRecognitionState.displayStatus == .notDetermined {
            openedSettingsFromNotDetermined = true
        }

        if !query.openApplicationSettings() {
            notice = YZGuideCopy.settingsFailed
        }
    }
}
