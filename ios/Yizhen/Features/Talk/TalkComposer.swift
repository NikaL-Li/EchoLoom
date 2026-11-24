import SwiftUI

struct TalkComposer: View {
    @Binding var draft: String
    let canSend: Bool
    let term: Term?
    let scene: SceneKind
    let textOnly: Bool
    let onSend: () -> Void
    let onClose: () -> Void

    @FocusState private var focused: Bool

    init(
        draft: Binding<String>,
        canSend: Bool,
        term: Term?,
        scene: SceneKind,
        textOnly: Bool,
        onSend: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self._draft = draft
        self.canSend = canSend
        self.term = term
        self.scene = scene
        self.textOnly = textOnly
        self.onSend = onSend
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(YZTheme.line)
                .frame(width: 38, height: 4)
                .padding(.top, 10)

            HStack(spacing: 8) {
                Text("我要说")
                    .font(YZTheme.font(size: 16, weight: .heavy, textStyle: .headline, maxSize: 23))
                    .foregroundStyle(YZTheme.ink)

                Spacer(minLength: 8)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(YZTheme.ink2)
                        .frame(width: 32, height: 32)
                        .background(YZTheme.bg, in: Circle())
                        .overlay {
                            Circle().stroke(
                                YZTheme.highContrast ? Color.black : YZTheme.line,
                                lineWidth: 1
                            )
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressButtonStyle())
                .accessibilityLabel("关闭输入")
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                TextField("打字给对方看，Enter 发送", text: $draft, axis: .vertical)
                    .font(YZTheme.font(size: 17, textStyle: .body, maxSize: 27))
                    .lineLimit(3...6)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(sendIfPossible)
                    .padding(12)
                    .background(
                        YZTheme.bg,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                YZTheme.highContrast ? Color.black : YZTheme.blueLine,
                                lineWidth: YZTheme.highContrast ? 2 : 1.5
                            )
                    }

                if let term {
                    TermHint(term: term, scene: scene)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Button(action: sendIfPossible) {
                Text("发送给对方")
                    .font(YZTheme.fontButton)
                    .foregroundStyle(
                        canSend
                            ? (YZTheme.highContrast ? Color.black : Color.white)
                            : YZTheme.ink3
                    )
                    .frame(maxWidth: .infinity, minHeight: YZTheme.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                            .fill(canSend ? YZTheme.blueFill : YZTheme.blueSoft)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                            .stroke(
                                YZTheme.highContrast ? Color.black : Color.clear,
                                lineWidth: 2
                            )
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(YZPressButtonStyle())
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.55)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(textOnly ? "全程文字模式：发送后只显示文字，不播报。" : "听不清？可在「我的」打开全程用文字。")
                Text("手语识别即将支持（占位）。")
            }
            .font(YZTheme.font(size: 11, textStyle: .caption2, maxSize: 16))
            .foregroundStyle(YZTheme.ink3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: YZTheme.contentMaxWidth)
        .background {
            YZTheme.card
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        }
        .overlay {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .stroke(
                    YZTheme.highContrast ? Color.black : YZTheme.line,
                    lineWidth: YZTheme.highContrast ? 2 : 1
                )
        }
        .yzCardShadow()
        .task {
            try? await Task.sleep(for: .milliseconds(120))
            focused = true
        }
    }

    private func sendIfPossible() {
        guard canSend else { return }
        onSend()
    }
}
