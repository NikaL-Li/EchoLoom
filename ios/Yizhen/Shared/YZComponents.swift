import SwiftUI

struct YZCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = YZTheme.pagePadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                YZTheme.card,
                in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
            )
            .overlay {
                if YZTheme.highContrast {
                    RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                        .stroke(Color.black, lineWidth: 2)
                }
            }
            .yzCardShadow()
    }
}

struct YZPageTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(YZTheme.fontPageTitle)
                .foregroundStyle(YZTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct YZSectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(YZTheme.fontSectionTitle)
                .foregroundStyle(YZTheme.ink)
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink3)
            }
        }
    }
}

struct YZPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(YZTheme.fontButton)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(YZPrimaryButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(title)
    }
}

private struct YZPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(YZTheme.highContrast ? Color.black : Color.white)
            .frame(minHeight: YZTheme.buttonHeight)
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
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct YZPillButton: View {
    enum Size {
        case regular
        case small

        var height: CGFloat {
            switch self {
            case .regular: YZTheme.pillHeight
            case .small: YZTheme.pillSmallHeight
            }
        }

        var font: Font {
            switch self {
            case .regular: YZTheme.fontPill
            case .small: YZTheme.fontPillSmall
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .regular: 14
            case .small: 10
            }
        }
    }

    let title: String
    var size: Size = .regular
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.font)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, size.horizontalPadding)
                .frame(height: size.height)
                .foregroundStyle(
                    isSelected
                        ? (YZTheme.highContrast ? Color.white : YZTheme.blue)
                        : YZTheme.ink2
                )
                .background(
                    Capsule().fill(
                        isSelected
                            ? (YZTheme.highContrast ? Color.black : YZTheme.blueSoft)
                            : YZTheme.card
                    )
                )
                .overlay(
                    Capsule().stroke(
                        isSelected && YZTheme.highContrast
                            ? Color.clear
                            : (isSelected ? YZTheme.blueLine : YZTheme.line),
                        lineWidth: YZTheme.highContrast ? 2 : 1
                    )
                )
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct YZListRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var iconColor: Color = YZTheme.blue
    var iconBackground: Color = YZTheme.blueSoft
    var trailingText: String?
    var showsChevron = true
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { row }
                    .buttonStyle(YZPressButtonStyle())
            } else {
                row
            }
        }
        .frame(minHeight: YZTheme.rowHeight)
        .contentShape(Rectangle())
    }

    private var row: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: YZTheme.iconSize, height: YZTheme.iconSize)
                .background(
                    iconBackground,
                    in: RoundedRectangle(cornerRadius: YZTheme.iconRadius, style: .continuous)
                )
                .overlay {
                    if YZTheme.highContrast {
                        RoundedRectangle(cornerRadius: YZTheme.iconRadius, style: .continuous)
                            .stroke(Color.black, lineWidth: 1.5)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(YZTheme.fontRowTitle)
                    .foregroundStyle(YZTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(YZTheme.fontCaption)
                        .foregroundStyle(YZTheme.ink3)
                }
            }

            Spacer(minLength: 8)

            if let trailingText {
                Text(trailingText)
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink3)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(YZTheme.ink3)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, YZTheme.pagePadding)
        .padding(.vertical, 10)
    }
}

struct YZSwitchRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(YZTheme.fontRowTitle)
                    .foregroundStyle(YZTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(YZTheme.fontCaption)
                        .foregroundStyle(YZTheme.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(YZTheme.highContrast ? .black : YZTheme.blueFill)
        }
        .padding(.horizontal, YZTheme.pagePadding)
        .frame(minHeight: YZTheme.rowHeight)
    }
}

struct YZSegmented: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, title in
                Button {
                    selection = index
                } label: {
                    Text(title)
                        .font(YZTheme.fontPillSmall)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 36 * min(YZTheme.scale, 1.4)
                        )
                }
                .buttonStyle(YZPressButtonStyle())
                .foregroundStyle(
                    selection == index
                        ? (YZTheme.highContrast ? Color.white : YZTheme.ink)
                        : YZTheme.ink3
                )
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selection == index
                                ? (YZTheme.highContrast ? Color.black : YZTheme.card)
                                : Color.clear
                        )
                )
                .shadow(
                    color: selection == index ? YZTheme.shadowColor : .clear,
                    radius: YZTheme.shadowRadius,
                    y: YZTheme.shadowY
                )
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityAddTraits(selection == index ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(YZTheme.bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
    }
}

struct YZToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(YZTheme.fontCaption)
            .foregroundStyle(YZTheme.toastForeground)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(YZTheme.toastBackground, in: Capsule())
            .overlay {
                if YZTheme.highContrast {
                    Capsule().stroke(Color.black, lineWidth: 2)
                }
            }
            .shadow(
                color: YZTheme.highContrast ? .clear : Color.black.opacity(0.18),
                radius: 8,
                y: 2
            )
    }
}

extension View {
    func yzToast(_ text: Binding<String?>) -> some View {
        modifier(YZToastModifier(text: text))
    }
}

private struct YZToastModifier: ViewModifier {
    @Binding var text: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let text {
                    YZToast(text: text)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                        .task(id: text) {
                            try? await Task.sleep(nanoseconds: 1_800_000_000)
                            if self.text == text {
                                self.text = nil
                            }
                        }
                }
            }
            .animation(.easeOut(duration: 0.18), value: text)
    }
}

struct YZPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
