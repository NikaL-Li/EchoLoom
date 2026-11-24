import SwiftUI

public struct SayList: View {
    public let items: [String]
    public let subSceneName: String
    @Binding public var playCounts: [String: Int]
    public let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    public init(
        items: [String],
        subSceneName: String,
        playCounts: Binding<[String: Int]>,
        onSelect: @escaping (String) -> Void
    ) {
        self.items = items
        self.subSceneName = subSceneName
        self._playCounts = playCounts
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                Text("这个场景还没有句子")
                    .font(.system(size: 13))
                    .foregroundStyle(SceneTheme.ink3(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items, id: \.self) { text in
                            row(text)
                        }
                    }
                }
            }

            Text("共 \(items.count) 条 · 点一句就能播")
                .font(.system(size: 12))
                .foregroundStyle(SceneTheme.ink3(scheme))
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 2)
        }
    }

    private func row(_ text: String) -> some View {
        let count = playCounts[text] ?? 0

        return Button {
            playCounts[text] = count + 1
            onSelect(text)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(SceneTheme.ink3(scheme))
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(SceneTheme.ink(scheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subSceneName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SceneTheme.ink3(scheme))
                }

                Spacer(minLength: 8)

                Text(statusText(count))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(
                        count > 0
                            ? SceneTheme.primary(scheme)
                            : SceneTheme.ink3(scheme)
                    )
                    .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 72)
            .background(count > 0 ? SceneTheme.playedBackground(scheme) : Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SceneTheme.line(scheme))
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(text)，\(statusText(count))")
    }

    private func statusText(_ count: Int) -> String {
        count > 0 ? "已播 \(count) 次" : "待播"
    }
}