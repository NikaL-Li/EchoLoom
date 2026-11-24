import SwiftUI

struct FaceView: View {
    let messages: [YZMessage]
    let sceneID: YZScene.ID
    let onReplay: (YZMessage) -> Void
    let onCopy: (YZMessage) -> Void
    let onOpenCard: (YZMessage) -> Void
    var isScrollLocked: Bool = false

    @Environment(\.yzTheme) private var theme

    private var otherMessages: [YZMessage] {
        messages.filter { $0.direction == .other }
    }

    private var mineMessages: [YZMessage] {
        messages.filter { $0.direction == .mine }
    }

    var body: some View {
        GeometryReader { proxy in
            let panelHeight = max(0, (proxy.size.height - 1) / 2)
            VStack(spacing: 0) {
                panel(
                    messages: otherMessages,
                    emptyText: "等待对方说话…",
                    rotated: true,
                    height: panelHeight
                )

                Rectangle()
                    .fill(theme.colors.separator)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                panel(
                    messages: mineMessages,
                    emptyText: "点「我要说」开始",
                    rotated: false,
                    height: panelHeight
                )
            }
        }
        .accessibilityIdentifier("featuretalk.face")
    }

    @ViewBuilder
    private func panel(messages: [YZMessage], emptyText: String, rotated: Bool, height: CGFloat) -> some View {
        Group {
            if messages.isEmpty {
                Text(emptyText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.colors.textWeak)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(Text(emptyText))
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageCard(
                                    message: message,
                                    sceneID: sceneID,
                                    onReplay: { onReplay(message) },
                                    onCopy: { onCopy(message) },
                                    onOpenCard: { onOpenCard(message) }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .scrollDisabled(isScrollLocked)
                    .onAppear {
                        scrollToLast(proxy, messages: messages)
                    }
                    .onChange(of: messages.last?.id) { _, _ in
                        scrollToLast(proxy, messages: messages)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .rotationEffect(rotated ? .degrees(180) : .zero)
        .accessibilityLabel(rotated ? "对方面板" : "我方面板")
    }

    private func scrollToLast(_ proxy: ScrollViewProxy, messages: [YZMessage]) {
        guard let lastID = messages.last?.id else { return }
        proxy.scrollTo(lastID, anchor: .bottom)
    }
}
#Preview("面对面分屏") {
    FaceView(
        messages: YZMockData.threeMessages,
        sceneID: "medical",
        onReplay: { _ in },
        onCopy: { _ in },
        onOpenCard: { _ in }
    )
    .padding()
    .environment(\.yzTheme, YZTheme.resolve(scheme: .light, reduceMotion: false))
}