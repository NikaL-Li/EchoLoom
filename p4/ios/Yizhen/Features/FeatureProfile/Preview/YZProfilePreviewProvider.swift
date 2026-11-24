#if DEBUG
import SwiftUI

struct YZProfilePreviewProvider: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView(
                appearance: .constant(.system),
                fontSize: .constant(.normal),
                isHighContrastEnabled: .constant(false),
                isTextOnlyMode: .constant(false),
                phraseCountText: "6 条",
                versionText: "译诊 1.0.0（1）",
                onPhrasesTap: {},
                onGuideTap: {}
            )
            .previewDisplayName("Default")

            ProfileView(
                appearance: .constant(.dark),
                fontSize: .constant(.xlarge),
                isHighContrastEnabled: .constant(false),
                isTextOnlyMode: .constant(true),
                phraseCountText: "6 条",
                versionText: "译诊 1.0.0（1）",
                onPhrasesTap: {},
                onGuideTap: {}
            )
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")
        }
    }
}
#endif