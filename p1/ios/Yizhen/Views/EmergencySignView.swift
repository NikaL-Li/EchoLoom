import SwiftUI

struct EmergencySignView: View {
    static let defaultText = "我听不见，请帮我打 120。"

    let text: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0xD6402B).ignoresSafeArea()

            VStack(spacing: 24) {
                Text(text)
                    .font(.system(size: 96, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                Text("轻点屏幕关闭")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityHint("轻点关闭大字牌")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    EmergencySignView(text: EmergencySignView.defaultText) {}
}