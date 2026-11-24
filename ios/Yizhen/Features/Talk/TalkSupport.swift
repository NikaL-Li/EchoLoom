import SwiftUI
import UIKit

enum TalkNoticeKind: Equatable {
    case listening
    case reconnecting
    case error
    case blocked
    case textOnly
}

struct TalkListenNotice: View {
    let kind: TalkNoticeKind
    let message: String
    var onClose: (() -> Void)?

    private var isProblem: Bool {
        kind == .error || kind == .blocked
    }

    var body: some View {
        HStack(spacing: 8) {
            if isProblem {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            } else {
                Circle()
                    .fill(kind == .textOnly ? YZTheme.ink3 : YZTheme.blue)
                    .frame(width: 7, height: 7)
            }

            Text(message)
                .font(YZTheme.font(size: 12, weight: .semibold, textStyle: .caption, maxSize: 17))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onClose {
                Button(action: onClose) {
                    Text("关闭")
                        .font(YZTheme.font(size: 12, weight: .semibold, textStyle: .caption, maxSize: 17))
                        .padding(.horizontal, 8)
                        .frame(minHeight: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressButtonStyle())
                .accessibilityLabel("关闭提示")
            }
        }
        .foregroundStyle(
            isProblem
                ? YZTheme.danger
                : (kind == .textOnly ? YZTheme.ink2 : YZTheme.blue)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isProblem
                        ? YZTheme.dangerSoft
                        : (kind == .textOnly ? YZTheme.bg : YZTheme.blueSoft)
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isProblem
                        ? YZTheme.danger
                        : (YZTheme.highContrast ? Color.black : YZTheme.blueLine),
                    lineWidth: YZTheme.highContrast ? 1.5 : 1
                )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message)
    }
}

struct TalkInterimCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("对方 · 正在说")
                .font(YZTheme.font(size: 12, weight: .medium, textStyle: .caption, maxSize: 17))
                .foregroundStyle(YZTheme.ink3)

            Text(text)
                .font(YZTheme.fontCardText)
                .italic()
                .foregroundStyle(YZTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                .fill(YZTheme.card)
        )
        .overlay {
            RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                .stroke(
                    YZTheme.highContrast ? Color.black : YZTheme.blueLine,
                    style: StrokeStyle(lineWidth: YZTheme.highContrast ? 1.5 : 1, dash: [4, 4])
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("对方正在说：\(text)")
    }
}

struct TalkEmptyState: View {
    var textOnly: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(YZTheme.blue)
                .frame(width: 76, height: 76)
                .background(YZTheme.blueSoft, in: Circle())
                .overlay {
                    if YZTheme.highContrast {
                        Circle().stroke(Color.black, lineWidth: 2)
                    }
                }
                .accessibilityHidden(true)

            Text("把手机放在桌上，点下面开始")
                .font(YZTheme.fontRowTitle)
                .foregroundStyle(YZTheme.ink)
                .multilineTextAlignment(.center)

            Text(
                textOnly
                    ? "点「我要说」打字给对方看。"
                    : "先点「听对方说」，或点「我要说」打字给对方看。"
            )
                .font(YZTheme.fontCaption)
                .foregroundStyle(YZTheme.ink3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TalkEmergencyBanner: View {
    let text: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(text)
                    .font(YZTheme.font(size: 14, weight: .bold, textStyle: .subheadline, maxSize: 21))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 4)
                Text("亮牌")
                    .font(YZTheme.font(size: 11, weight: .bold, textStyle: .caption2, maxSize: 15))
                    .padding(.horizontal, 8)
                    .frame(minHeight: 24)
                    .background(Color.white.opacity(0.18), in: Capsule())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                Color(hex: 0xD6402B),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(YZTheme.highContrast ? 1 : 0), lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("紧急提示：\(text)，点一下打开大字牌")
    }
}

struct TalkDockButton: View {
    enum Kind {
        case primary
        case secondary
    }

    let title: String
    let kind: Kind
    let isEnabled: Bool
    let action: () -> Void

    private var foreground: Color {
        guard isEnabled else { return YZTheme.ink3 }
        if YZTheme.highContrast { return .black }
        return kind == .primary ? .white : YZTheme.blue
    }

    private var background: Color {
        guard isEnabled else { return YZTheme.bg }
        if YZTheme.highContrast { return .white }
        return kind == .primary ? YZTheme.blueFill : YZTheme.card
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(YZTheme.font(size: 15, weight: .bold, textStyle: .body, maxSize: 22))
                .foregroundStyle(foreground)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: YZTheme.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                        .fill(background)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                        .stroke(
                            isEnabled && (kind == .secondary || YZTheme.highContrast)
                                ? (YZTheme.highContrast ? Color.black : YZTheme.blueLine)
                                : Color.clear,
                            lineWidth: YZTheme.highContrast ? 2 : 1
                        )
                }
                .contentShape(Rectangle())
                .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(YZPressButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

struct RecordingGlow: View {
    let isActive: Bool
    let reduceMotion: Bool

    @State private var breathing = false

    init(isActive: Bool, reduceMotion: Bool) {
        self.isActive = isActive
        self.reduceMotion = reduceMotion
    }

    @ViewBuilder
    var body: some View {
        if YZTheme.highContrast {
            EmptyView()
        } else {
            HStack(spacing: 0) {
                edge
                Spacer(minLength: 0)
                edge
            }
            .ignoresSafeArea()
            .opacity(isActive ? (reduceMotion ? 0.6 : (breathing ? 0.95 : 0.35)) : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                value: breathing
            )
            .onAppear {
                breathing = isActive && !reduceMotion
            }
            .onChange(of: isActive) { _, active in
                breathing = active && !reduceMotion
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var edge: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, YZTheme.blue.opacity(0.58), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3)
            .blur(radius: 1.5)
            .padding(.vertical, 70)
    }
}
