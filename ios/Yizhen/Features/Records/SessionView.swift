import SwiftUI

struct SessionView: View {
    let session: YZSession
    let onBack: () -> Void

    private let summaryProvider: YZSessionSummaryProviding = YZDefaultSessionSummaryProvider()

    @State private var largeSentence: YZSentenceDisplayModel?
    @State private var summaryExpanded = false
    @State private var summaryState: YZSessionSummaryUIState = .hidden
    @State private var generationTask: Task<Void, Never>?

    init(session: YZSession, onBack: @escaping () -> Void) {
        self.session = session
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            YZSessionStyle.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    YZSessionHeaderView(
                        title: YZSessionCopy.title(for: session),
                        subtitle: YZSessionCopy.subtitle(for: session),
                        canGenerateSummary: !session.turns.isEmpty,
                        onBack: onBack,
                        onGenerateSummary: handleGenerateSummary
                    )

                    let sentences = yzSentenceModels(for: session)

                    if sentences.isEmpty {
                        Text(YZSessionCopy.emptySentences)
                            .font(YZSessionFont.body)
                            .foregroundStyle(YZSessionStyle.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                YZSessionStyle.cardBackground,
                                in: RoundedRectangle(
                                    cornerRadius: YZTheme.cardRadius,
                                    style: .continuous
                                )
                            )
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(sentences) { sentence in
                                YZSessionSentenceCardView(
                                    sentence: sentence,
                                    onTap: { largeSentence = sentence }
                                )
                            }
                        }
                    }

                    if !session.turns.isEmpty {
                        ShareLink(item: YZSessionTextExporter.text(for: session)) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("导出文字")
                            }
                            .font(YZSessionFont.caption)
                            .foregroundStyle(YZSessionStyle.primary)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(YZSessionStyle.primarySoft, in: Capsule())
                            .overlay {
                                if YZTheme.highContrast {
                                    Capsule().stroke(Color.black, lineWidth: 2)
                                }
                            }
                        }
                        .accessibilityLabel("导出这次对话的文字")
                        .accessibilityHint("打开系统分享面板，可复制或保存为文本")
                    }

                    if summaryExpanded {
                        YZSessionSummaryCardView(
                            state: summaryState,
                            onRetry: startSummary,
                            onCollapse: { summaryExpanded = false }
                        )
                    }
                }
                .padding(.horizontal, YZTheme.pagePadding)
                .padding(.top, 18)
                .padding(.bottom, YZTheme.tabBottomInset)
                .yzContentWidth()
            }
            .scrollIndicators(.hidden)

        }
        .fullScreenCover(item: $largeSentence) { sentence in
            SignView(text: sentence.text, tone: .plain) {
                largeSentence = nil
            }
        }
        .onDisappear {
            generationTask?.cancel()
        }
    }

    private func handleGenerateSummary() {
        if summaryExpanded {
            summaryExpanded = false
            return
        }

        summaryExpanded = true

        if session.turns.isEmpty {
            summaryState = .empty
            return
        }

        switch summaryState {
        case .content, .empty, .unavailable, .generating:
            return
        case .hidden, .failed:
            startSummary()
        }
    }

    private func startSummary() {
        guard summaryState != .generating else { return }

        summaryState = .generating
        generationTask?.cancel()
        generationTask = Task {
            let result = await summaryProvider.summary(for: session)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                switch result {
                case .content(let lines):
                    summaryState = lines.isEmpty ? .empty : .content(lines)
                case .empty:
                    summaryState = .empty
                case .failed:
                    summaryState = .failed
                case .unavailable:
                    summaryState = .unavailable
                }
            }
        }
    }
}
