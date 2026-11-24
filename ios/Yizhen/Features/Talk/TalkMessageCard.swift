import SwiftUI

struct TalkMessageCard: View {
    let turn: YZTurn
    let scene: SceneKind
    let onReplay: () -> Void
    let onCopy: () -> Void
    let onOpenSign: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        turn: YZTurn,
        scene: SceneKind,
        onReplay: @escaping () -> Void,
        onCopy: @escaping () -> Void,
        onOpenSign: @escaping () -> Void
    ) {
        self.turn = turn
        self.scene = scene
        self.onReplay = onReplay
        self.onCopy = onCopy
        self.onOpenSign = onOpenSign
    }

    private var isMine: Bool { turn.role == .me }

    private var speakerLabel: String {
        let who = scene == .medical ? "医生" : "对方"
        return "\(who) · \(Self.timeFormatter.string(from: turn.date))"
    }

    var body: some View {
        VStack(spacing: 0) {
            subject

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    if isMine {
                        statusPill
                    }
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        actionRow
                    }
                }
                .padding(.top, 10)
            } else {
                HStack(spacing: 0) {
                    if isMine {
                        statusPill
                    }
                    Spacer(minLength: 8)
                    actionRow
                }
                .padding(.top, 10)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 14)
        .padding(.leading, isMine ? 16 : 20)
        .padding(.trailing, isMine ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                .fill(YZTheme.card)
        )
        .overlay {
            RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                .stroke(
                    YZTheme.highContrast ? Color.black : YZTheme.line,
                    lineWidth: YZTheme.highContrast ? 2 : 1
                )
        }
        .overlay(alignment: isMine ? .leading : .trailing) {
            Rectangle()
                .fill(isMine ? (YZTheme.highContrast ? Color.black : YZTheme.blueFill) : (YZTheme.highContrast ? Color.black : YZTheme.green))
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous))
        .yzCardShadow()
    }

    private var subject: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !isMine {
                Text(speakerLabel)
                    .font(YZTheme.font(size: 12, weight: .medium, textStyle: .caption, maxSize: 17))
                    .foregroundStyle(YZTheme.ink3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Text(turn.text)
                .font(YZTheme.fontCardText)
                .foregroundStyle(YZTheme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenSign)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isMine ? "我说" : "对方说")：\(turn.text)")
        .accessibilityHint("轻点看全屏大字")
    }

    private var statusPill: some View {
        Text(turn.status.isEmpty ? "文字直达" : turn.status)
            .font(YZTheme.font(size: 11, weight: .semibold, textStyle: .caption2, maxSize: 15))
            .foregroundStyle(statusForeground)
            .padding(.horizontal, 9)
            .frame(minHeight: 24)
            .background(statusBackground, in: Capsule())
            .overlay {
                if YZTheme.highContrast {
                    Capsule().stroke(Color.black, lineWidth: 1)
                }
            }
    }

    private var actionRow: some View {
        HStack(spacing: 4) {
            actionButton("重播", action: onReplay)
            actionButton("复制", action: onCopy)
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(YZTheme.font(size: 11, weight: .medium, textStyle: .caption2, maxSize: 15))
                .foregroundStyle(YZTheme.ink2)
                .padding(.horizontal, 9)
                .frame(minHeight: 28)
                .background(YZTheme.bg, in: Capsule())
                .overlay {
                    Capsule().stroke(
                        YZTheme.highContrast ? Color.black : YZTheme.line,
                        lineWidth: YZTheme.highContrast ? 1 : 1
                    )
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel(title)
    }

    private var statusForeground: Color {
        switch turn.status {
        case "已播报": return YZTheme.green
        case "播报失败": return YZTheme.danger
        default: return YZTheme.ink2
        }
    }

    private var statusBackground: Color {
        switch turn.status {
        case "已播报": return YZTheme.greenSoft
        case "播报失败": return YZTheme.dangerSoft
        default: return YZTheme.bg
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
