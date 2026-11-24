import SwiftUI
import UIKit

enum SignTone: Equatable {
    case plain
    case emergency
}

struct SignPresentation: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let tone: SignTone

    static func == (lhs: SignPresentation, rhs: SignPresentation) -> Bool {
        lhs.id == rhs.id
    }
}

struct SignView: View {
    let text: String
    let tone: SignTone
    let onDismiss: () -> Void

    @State private var isIdleTimerDisabled = false

    private var backgroundColor: Color {
        tone == .emergency ? Color(yzHex: 0xD6402B) : Color(yzHex: 0xFFFFFF)
    }

    private var foregroundColor: Color {
        tone == .emergency ? Color(yzHex: 0xFFFFFF) : Color(yzHex: 0x000000)
    }

    private var hintColor: Color {
        tone == .emergency ? Color(yzHex: 0xFFFFFF, opacity: 0.92) : Color(yzHex: 0x4A5568)
    }

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height
            ZStack(alignment: .bottom) {
                backgroundColor
                    .ignoresSafeArea()

                signText(in: proxy.size, landscape: landscape)

                Text("点任意处退出")
                    .font(.system(size: landscape ? 12 : 14, weight: .regular))
                    .foregroundStyle(hintColor)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, max(16, proxy.safeAreaInsets.bottom + 16))
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    onDismiss()
                }
            )
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(text)。点任意处退出"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("退出大字牌")) {
            onDismiss()
        }
        .accessibilityIdentifier("featuretalk.sign")
        .onAppear {
            guard !isIdleTimerDisabled else { return }
            UIApplication.shared.isIdleTimerDisabled = true
            isIdleTimerDisabled = true
        }
        .onDisappear {
            guard isIdleTimerDisabled else { return }
            UIApplication.shared.isIdleTimerDisabled = false
            isIdleTimerDisabled = false
        }
    }

    @ViewBuilder
    private func signText(in size: CGSize, landscape: Bool) -> some View {
        let horizontalPadding: CGFloat = 24
        let verticalPadding: CGFloat = 64
        let maxWidth = max(0, size.width * 0.94)
        let maxHeight = max(0, size.height - verticalPadding - 40)

        if landscape {
            let fontSize = min(220, max(96, size.height * 0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, horizontalPadding)
            }
            .frame(maxWidth: size.width, maxHeight: maxHeight)
        } else {
            let fontSize = fittedFontSize(
                text: text,
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                upperBound: 160,
                lowerBound: 72
            )
            ScrollView(.vertical, showsIndicators: false) {
                Text(text)
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(fontSize * 0.16)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: maxWidth, minHeight: maxHeight, alignment: .center)
            }
            .frame(maxWidth: size.width, maxHeight: maxHeight)
        }
    }

    private func fittedFontSize(
        text: String,
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        upperBound: CGFloat,
        lowerBound: CGFloat
    ) -> CGFloat {
        guard maxWidth > 0, maxHeight > 0 else { return lowerBound }
        var size = upperBound
        while size > lowerBound {
            let font = UIFont.systemFont(ofSize: size, weight: .heavy)
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            if rect.height * 1.16 <= maxHeight {
                return size
            }
            size -= 4
        }
        return lowerBound
    }
}

extension SignView {
    static func emergency(onDismiss: @escaping () -> Void) -> SignView {
        SignView(text: "我听不见，请帮我打 120。", tone: .emergency, onDismiss: onDismiss)
    }
}
#Preview("大字牌 普通") {
    SignView(text: "请问您哪里不舒服？", tone: .plain, onDismiss: {})
}

#Preview("大字牌 紧急") {
    SignView.emergency(onDismiss: {})
}

#Preview("大字牌 横屏") {
    SignView(text: "请先去一楼缴费，再到二楼取药。", tone: .plain, onDismiss: {})
        .frame(width: 844, height: 390)
}