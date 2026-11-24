import SwiftUI

struct YZGuideStepCardView: View {
    let step: YZGuideStep

    var body: some View {
        YZCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(YZGuideStyle.primaryFill)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(step.id)")
                                .font(YZGuideFont.stepNumber)
                                .foregroundStyle(YZTheme.highContrast ? .black : .white)
                        )
                        .overlay {
                            if YZTheme.highContrast {
                                Circle().stroke(Color.black, lineWidth: 2)
                            }
                        }

                    Text(step.title)
                        .font(YZGuideFont.sectionTitle)
                        .foregroundStyle(YZGuideStyle.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }

                section(title: YZGuideCopy.operation, text: step.operation)
                section(title: YZGuideCopy.expectation, text: step.expectation)
                section(title: YZGuideCopy.stuck, text: step.stuck)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "第 \(step.id) 步，\(step.title)。操作：\(step.operation)。预期：\(step.expectation)。卡住时：\(step.stuck)。"
        )
    }

    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(YZGuideFont.caption)
                .foregroundStyle(YZGuideStyle.primary)

            Text(text)
                .font(YZGuideFont.body)
                .foregroundStyle(YZGuideStyle.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 38)
    }
}

struct YZGuidePermissionBadgeView: View {
    let status: YZPermissionDisplayStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
            Text(status.text)
                .font(YZGuideFont.badge)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 12)
        .frame(height: YZTheme.pillHeight)
        .background(backgroundColor, in: Capsule())
        .overlay {
            if YZTheme.highContrast {
                Capsule().stroke(Color.black, lineWidth: 2)
            }
        }
        .accessibilityLabel(status.text)
    }

    private var iconName: String {
        switch status {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .authorized:
            return YZTheme.highContrast ? YZGuideStyle.textPrimary : .white
        case .denied:
            return YZTheme.highContrast ? YZGuideStyle.danger : .white
        case .notDetermined:
            return YZGuideStyle.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .authorized:
            return YZTheme.highContrast ? YZGuideStyle.cardBackground : YZGuideStyle.successFill
        case .denied:
            return YZTheme.highContrast ? YZGuideStyle.cardBackground : YZGuideStyle.danger
        case .notDetermined:
            return YZGuideStyle.mutedSurface
        }
    }
}

struct YZGuidePermissionRowView: View {
    let name: String
    let state: YZGuidePermissionRowState
    let onOpenSettings: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    nameView
                    Spacer(minLength: 8)
                    statusView
                    settingsButton
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        nameView
                        Spacer(minLength: 8)
                        statusView
                    }
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        settingsButton
                    }
                }
            }

            if state.isRestricted {
                Text(YZGuideCopy.restrictedNote)
                    .font(YZGuideFont.tag)
                    .foregroundStyle(YZGuideStyle.textTertiary)
            }
        }
        .padding(.horizontal, YZTheme.pagePadding)
        .padding(.vertical, 14)
        .frame(minHeight: YZTheme.rowHeight)
        .accessibilityElement(children: .contain)
    }

    private var nameView: some View {
        Text(name)
            .font(YZGuideFont.sectionTitle)
            .foregroundStyle(YZGuideStyle.textPrimary)
    }

    private var settingsButton: some View {
        YZPillButton(
            title: YZGuideCopy.openSettings,
            size: .small,
            action: onOpenSettings
        )
    }

    @ViewBuilder
    private var statusView: some View {
        switch state {
        case .loading:
            Text(YZGuideCopy.loading)
                .font(YZGuideFont.caption)
                .foregroundStyle(YZGuideStyle.textSecondary)

        case .resolved(let status, _):
            YZGuidePermissionBadgeView(status: status)

        case .failed:
            HStack(spacing: 8) {
                Text(YZGuideCopy.failed)
                    .font(YZGuideFont.caption)
                    .foregroundStyle(YZGuideStyle.danger)
                YZPillButton(
                    title: YZGuideCopy.retry,
                    size: .small,
                    action: onRetry
                )
            }
        }
    }
}

struct YZGuidePermissionCardView: View {
    let microphoneState: YZGuidePermissionRowState
    let speechRecognitionState: YZGuidePermissionRowState
    let onOpenSettings: () -> Void
    let onRetry: () -> Void

    var body: some View {
        YZCard(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text(YZGuideCopy.permissionTitle)
                        .font(YZGuideFont.sectionTitle)
                        .foregroundStyle(YZGuideStyle.textPrimary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, YZTheme.pagePadding)
                .padding(.top, 16)

                YZGuidePermissionRowView(
                    name: YZGuideCopy.microphone,
                    state: microphoneState,
                    onOpenSettings: onOpenSettings,
                    onRetry: onRetry
                )

                Divider()
                    .overlay(YZGuideStyle.separator)
                    .padding(.leading, YZTheme.pagePadding)

                YZGuidePermissionRowView(
                    name: YZGuideCopy.speechRecognition,
                    state: speechRecognitionState,
                    onOpenSettings: onOpenSettings,
                    onRetry: onRetry
                )
            }
            .padding(.bottom, 4)

        }
    }
}
