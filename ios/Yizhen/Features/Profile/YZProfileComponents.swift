import SwiftUI

struct YZProfileUserCardView: View {
    var body: some View {
        YZCard {
            HStack(spacing: 16) {
                Circle()
                    .fill(YZProfileStyle.primaryFill)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(YZProfileCopy.avatarInitial)
                            .font(YZProfileFont.avatar)
                            .foregroundStyle(YZTheme.highContrast ? .black : .white)
                    )
                    .overlay {
                        if YZTheme.highContrast {
                            Circle().stroke(Color.black, lineWidth: 2)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(YZProfileCopy.userName)
                        .font(YZProfileFont.rowTitle)
                        .foregroundStyle(YZProfileStyle.textPrimary)

                    Text(YZProfileCopy.userSubtitle)
                        .font(YZProfileFont.caption)
                        .foregroundStyle(YZProfileStyle.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(YZProfileCopy.userName)，\(YZProfileCopy.userSubtitle)")
    }
}

struct YZProfileEntryCardView: View {
    let phraseCountText: String
    let onPhrasesTap: () -> Void
    let onGuideTap: () -> Void

    var body: some View {
        YZCard(padding: 0) {
            VStack(spacing: 0) {
                YZListRow(
                    icon: "text.bubble",
                    title: YZProfileCopy.phrases,
                    iconColor: YZTheme.green,
                    iconBackground: YZTheme.greenSoft,
                    trailingText: phraseCountText.isEmpty ? nil : phraseCountText,
                    action: onPhrasesTap
                )

                Divider()
                    .overlay(YZProfileStyle.separator)
                    .padding(.leading, 68)

                YZListRow(
                    icon: "book",
                    title: YZProfileCopy.guide,
                    subtitle: YZProfileCopy.guideSubtitle,
                    action: onGuideTap
                )
            }
        }
    }
}

struct YZProfileAppearanceCardView: View {
    @Binding var appearance: YZThemeMode

    var body: some View {
        YZCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(YZProfileCopy.appearance)
                    .font(YZProfileFont.rowTitle)
                    .foregroundStyle(YZProfileStyle.textPrimary)

                YZSegmented(
                    options: YZProfileCopy.appearanceOptions,
                    selection: appearanceIndex
                )

                Text(YZProfileCopy.appearanceNote)
                    .font(YZProfileFont.caption)
                    .foregroundStyle(YZProfileStyle.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if YZTheme.highContrast {
                    Text("高对比模式已开启，会强制使用浅色背景。")
                        .font(YZProfileFont.caption)
                        .foregroundStyle(YZProfileStyle.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var appearanceIndex: Binding<Int> {
        Binding(
            get: { YZProfileCopy.index(for: appearance) },
            set: { appearance = YZProfileCopy.mode(for: $0) }
        )
    }
}

struct YZProfileSettingsCardView: View {
    @Binding var isTextOnlyMode: Bool
    @Binding var fontSize: YZFontSize
    @Binding var isHighContrastEnabled: Bool

    var body: some View {
        YZCard(padding: 0) {
            VStack(spacing: 0) {
                YZSwitchRow(
                    title: YZProfileCopy.textOnly,
                    subtitle: YZProfileCopy.textOnlyNote,
                    isOn: $isTextOnlyMode
                )

                Divider()
                    .overlay(YZProfileStyle.separator)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        fontSizeTitle
                        Spacer(minLength: 8)
                        fontSizePills
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        fontSizeTitle
                        fontSizePills
                    }
                }
                .padding(.horizontal, YZTheme.pagePadding)
                .frame(minHeight: YZTheme.rowHeight)

                Divider()
                    .overlay(YZProfileStyle.separator)

                YZSwitchRow(
                    title: YZProfileCopy.highContrast,
                    isOn: $isHighContrastEnabled
                )
            }
        }
    }
}

private extension YZProfileSettingsCardView {
    var fontSizeTitle: some View {
        Text(YZProfileCopy.fontSize)
            .font(YZProfileFont.rowTitle)
            .foregroundStyle(YZProfileStyle.textPrimary)
    }

    var fontSizePills: some View {
        HStack(spacing: 8) {
            ForEach(YZFontSize.allCases, id: \.rawValue) { size in
                YZPillButton(
                    title: YZProfileCopy.title(for: size),
                    isSelected: fontSize.rawValue == size.rawValue
                ) {
                    fontSize = size
                }
            }
        }
    }
}

struct YZProfileVersionFooterView: View {
    let versionText: String

    var body: some View {
        if !versionText.isEmpty {
            Text(versionText)
                .font(YZProfileFont.tag)
                .foregroundStyle(YZProfileStyle.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }
}
