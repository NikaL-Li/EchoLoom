import SwiftUI

struct ProfileView: View {
    @Binding private var appearance: YZThemeMode
    @Binding private var fontSize: YZFontSize
    @Binding private var isHighContrastEnabled: Bool
    @Binding private var isTextOnlyMode: Bool

    private let phraseCountText: String
    private let versionText: String
    private let onPhrasesTap: () -> Void
    private let onGuideTap: () -> Void

    init(
        appearance: Binding<YZThemeMode>,
        fontSize: Binding<YZFontSize>,
        isHighContrastEnabled: Binding<Bool>,
        isTextOnlyMode: Binding<Bool>,
        phraseCountText: String,
        versionText: String,
        onPhrasesTap: @escaping () -> Void,
        onGuideTap: @escaping () -> Void
    ) {
        self._appearance = appearance
        self._fontSize = fontSize
        self._isHighContrastEnabled = isHighContrastEnabled
        self._isTextOnlyMode = isTextOnlyMode
        self.phraseCountText = phraseCountText
        self.versionText = versionText
        self.onPhrasesTap = onPhrasesTap
        self.onGuideTap = onGuideTap
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
                YZPageTitle(title: YZProfileCopy.pageTitle)

                YZProfileUserCardView()

                YZProfileEntryCardView(
                    phraseCountText: phraseCountText,
                    onPhrasesTap: onPhrasesTap,
                    onGuideTap: onGuideTap
                )

                YZProfileAppearanceCardView(appearance: $appearance)

                YZProfileSettingsCardView(
                    isTextOnlyMode: $isTextOnlyMode,
                    fontSize: $fontSize,
                    isHighContrastEnabled: $isHighContrastEnabled
                )

                YZProfileVersionFooterView(versionText: versionText)
                    .padding(.top, 8)
            }
            .padding(.horizontal, YZTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, YZTheme.tabBottomInset)
        }
        .scrollIndicators(.hidden)
    }
}