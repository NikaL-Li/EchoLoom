import SwiftUI

struct MessageListView: View {
    let messages: [YZMessage]
    let sceneID: YZScene.ID
    let revealedIDs: Set<YZMessage.ID>
    let onReveal: (YZMessage.ID) -> Void
    let onReplay: (YZMessage) -> Void
    let onCopy: (YZMessage) -> Void
    let onOpenCard: (YZMessage) -> Void
    let scrollTargetID: YZMessage.ID?
    let onScrollConsumed: () -> Void

    @Environment(\.yzTheme) private var theme

    var body: some View {
        Group {
            if messages.isEmpty {
                EmptyMessageView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: theme.metrics.spacing.cardGap) {
                            ForEach(messages) { message in
                                MessageCard(
                                    message: message,
                                    sceneID: sceneID,
                                    onReplay: { onReplay(message) },
                                    onCopy: { onCopy(message) },
                                    onOpenCard: { onOpenCard(message) }
                                )
                                .id(message.id)
                                .yzCardEntrance(isVisible: revealedIDs.contains(message.id))
                                .onAppear {
                                    if !revealedIDs.contains(message.id) {
                                        onReveal(message.id)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, theme.metrics.spacing.cardGap)
                    }
                    .onAppear {
                        if let scrollTargetID {
                            scroll(proxy, to: scrollTargetID)
                        }
                    }
                    .onChange(of: scrollTargetID) { _, target in
                        guard let target else { return }
                        scroll(proxy, to: target)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: YZMessage.ID) {
        proxy.scrollTo(id, anchor: .bottom)
        DispatchQueue.main.async {
            proxy.scrollTo(id, anchor: .bottom)
            onScrollConsumed()
        }
    }
}