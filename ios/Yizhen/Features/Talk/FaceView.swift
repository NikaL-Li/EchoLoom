import SwiftUI

struct FaceView: View {
    let turns: [YZTurn]
    let scene: SceneKind
    let onOpenSign: (YZTurn) -> Void

    private var otherTurns: [YZTurn] {
        turns.filter { $0.role == .other }
    }

    private var mineTurns: [YZTurn] {
        turns.filter { $0.role == .me }
    }

    var body: some View {
        GeometryReader { proxy in
            let panelHeight = max(0, (proxy.size.height - 1) / 2)
            VStack(spacing: 0) {
                panel(
                    turns: otherTurns,
                    emptyText: "等待对方说话…",
                    rotated: true,
                    height: panelHeight
                )

                Rectangle()
                    .fill(YZTheme.line)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                panel(
                    turns: mineTurns,
                    emptyText: "点「我要说」开始",
                    rotated: false,
                    height: panelHeight
                )
            }
        }
    }

    @ViewBuilder
    private func panel(turns: [YZTurn], emptyText: String, rotated: Bool, height: CGFloat) -> some View {
        Group {
            if turns.isEmpty {
                Text(emptyText)
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink3)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(emptyText)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(turns) { turn in
                                Button {
                                    onOpenSign(turn)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(turn.role == .me ? "我" : (scene == .medical ? "医生" : "对方"))
                                            .font(YZTheme.font(size: 11, weight: .semibold, textStyle: .caption2, maxSize: 15))
                                            .foregroundStyle(YZTheme.ink3)

                                        Text(turn.text)
                                            .font(YZTheme.font(size: 20, weight: .semibold, textStyle: .title3, maxSize: 32))
                                            .foregroundStyle(YZTheme.ink)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        YZTheme.card,
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(
                                                YZTheme.highContrast ? Color.black : YZTheme.line,
                                                lineWidth: YZTheme.highContrast ? 2 : 1
                                            )
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(YZPressButtonStyle())
                                .id(turn.id)
                                .accessibilityLabel("\(turn.role == .me ? "我说" : "对方说")：\(turn.text)")
                                .accessibilityHint("轻点看全屏大字")
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                    }
                    .onAppear {
                        scrollToLast(proxy, id: turns.last?.id)
                    }
                    .onChange(of: turns.last?.id) { _, lastID in
                        scrollToLast(proxy, id: lastID)
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

    private func scrollToLast(_ proxy: ScrollViewProxy, id: UUID?) {
        guard let id else { return }
        proxy.scrollTo(id, anchor: .bottom)
    }
}
