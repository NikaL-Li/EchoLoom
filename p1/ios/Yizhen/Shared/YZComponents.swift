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
            .background(YZTheme.card, in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous))
            .yzCardShadow()
    }
}

struct YZPageTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(YZTheme.fontPageTitle)
                .foregroundStyle(YZTheme.ink)
                .lineSpacing(0)
            if let subtitle {
                Text(subtitle)
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct YZSectionTitle: View {
    let title: String
    var trailing: String? = nil

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
            .foregroundStyle(.white)
            .frame(height: YZTheme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: YZTheme.buttonRadius, style: .continuous)
                    .fill(YZTheme.blueFill)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
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
                .padding(.horizontal, size.horizontalPadding)
                .frame(height: size.height)
                .foregroundStyle(isSelected ? YZTheme.blue : YZTheme.ink2)
                .background(
                    Capsule()
                        .fill(isSelected ? YZTheme.blueSoft : YZTheme.card)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? YZTheme.blueLine : YZTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(YZPressableStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct YZPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct YZListRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = YZTheme.blue
    var iconBackground: Color = YZTheme.blueSoft
    var trailingText: String? = nil
    var showsChevron: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { row }
                    .buttonStyle(YZPressableStyle())
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
    var subtitle: String? = nil
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
                }
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(YZTheme.blueFill)
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
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == index ? YZTheme.ink : YZTheme.ink3)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selection == index ? YZTheme.card : Color.clear)
                )
                .shadow(
                    color: selection == index ? YZTheme.shadowColor : Color.clear,
                    radius: YZTheme.shadowRadius,
                    y: YZTheme.shadowY
                )
                .accessibilityAddTraits(selection == index ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(YZTheme.bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct YZToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(YZTheme.fontCaption)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: 0x0F1A2E), in: Capsule())
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 2)
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