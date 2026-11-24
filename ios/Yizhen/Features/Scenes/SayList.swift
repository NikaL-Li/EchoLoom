import SwiftUI

struct SayList: View {
    let items: [String]
    let subSceneName: String
    @Binding var playCounts: [String: Int]
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    init(
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

    var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                Text("这个场景还没有句子")
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(SceneTheme.ink3(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items, id: \.self) { text in
                            row(text)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            Text("共 \(items.count) 条 · 点一句就能播")
                .font(YZTheme.font(size: 12, textStyle: .caption, maxSize: 17))
                .foregroundStyle(SceneTheme.ink3(scheme))
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 4)
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
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(SceneTheme.ink3(scheme))
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(YZTheme.font(size: 18, weight: .medium, textStyle: .body, maxSize: 28))
                        .foregroundStyle(SceneTheme.ink(scheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subSceneName)
                        .font(YZTheme.font(size: 12, weight: .medium, textStyle: .caption, maxSize: 17))
                        .foregroundStyle(SceneTheme.ink3(scheme))
                }

                Spacer(minLength: 8)

                Text(statusText(count))
                    .font(YZTheme.font(size: 12, weight: .medium, textStyle: .caption, maxSize: 17))
                    .foregroundStyle(count > 0 ? SceneTheme.primary(scheme) : SceneTheme.ink3(scheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
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
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("\(text)，\(statusText(count))")
    }

    private func statusText(_ count: Int) -> String {
        count > 0 ? "已播 \(count) 次" : "待播"
    }
}
