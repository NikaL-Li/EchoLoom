import SwiftUI

struct SummaryCard: View {
    let items: [String]
    let onCopy: () -> Void
    var onCollapse: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("这次要记住")
                    .font(YZTheme.font(size: 15, weight: .heavy, textStyle: .headline, maxSize: 22))
                    .foregroundStyle(YZTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                if let onCollapse {
                    Button(action: onCollapse) {
                        Text("收起")
                            .font(YZTheme.fontPillSmall)
                            .foregroundStyle(YZTheme.blue)
                            .padding(.horizontal, 10)
                            .frame(minHeight: 32)
                            .background(YZTheme.card, in: Capsule())
                            .overlay {
                                Capsule().stroke(
                                    YZTheme.highContrast ? Color.black : YZTheme.blueLine,
                                    lineWidth: YZTheme.highContrast ? 1.5 : 1
                                )
                            }
                    }
                    .buttonStyle(YZPressButtonStyle())
                    .accessibilityLabel("收起要点")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Text("\(index + 1). \(item)")
                        .font(YZTheme.font(size: 14, textStyle: .subheadline, maxSize: 22))
                        .foregroundStyle(YZTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 10)

            Button(action: onCopy) {
                Text("复制要点")
                    .font(YZTheme.font(size: 14, weight: .bold, textStyle: .subheadline, maxSize: 21))
                    .foregroundStyle(YZTheme.highContrast ? Color.black : Color.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                            .fill(YZTheme.blueFill)
                    )
                    .overlay {
                        if YZTheme.highContrast {
                            RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                                .stroke(Color.black, lineWidth: 2)
                        }
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(YZPressButtonStyle())
            .padding(.top, 12)
            .accessibilityLabel("复制要点")
        }
        .padding(16)
        .background(
            YZTheme.blueSoft,
            in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
        )
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
