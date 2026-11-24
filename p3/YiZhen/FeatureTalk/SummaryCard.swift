import SwiftUI

struct SummaryCard: View {
    let items: [String]
    let onCopy: () -> Void

    @Environment(\.yzTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("这次要记住")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Text("\(index + 1). \(item)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 10)

            Button(action: onCopy) {
                Text("复制要点")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.colors.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: theme.metrics.radius.button, style: .continuous)
                            .fill(theme.colors.accentFill)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(YZPressableButtonStyle())
            .padding(.top, 12)
            .accessibilityLabel(Text("复制要点"))
            .accessibilityIdentifier("featuretalk.summary.copy")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous)
                .fill(theme.colors.accentSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radius.card, style: .continuous)
                .strokeBorder(theme.colors.accentStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("featuretalk.summary.card")
    }
}
#Preview("要点卡") {
    SummaryCard(
        items: [
            "我头晕、头痛，已经疼了三天。",
            "先量血压，再去做一个血常规检查。",
            "接下来：先去一楼缴费，再到二楼取药。"
        ],
        onCopy: {}
    )
    .padding()
    .environment(\.yzTheme, YZTheme.resolve(scheme: .light, reduceMotion: false))
}