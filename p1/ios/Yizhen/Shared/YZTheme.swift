import SwiftUI

enum YZThemeMode: String, Codable, CaseIterable {
    case system
    case light
    case dark
}

enum YZFontSize: Int, Codable, CaseIterable {
    case normal = 18
    case large = 24
    case xlarge = 30

    var points: CGFloat { CGFloat(rawValue) }
}

enum YZTheme {
    static let bg = Color("YZBg")
    static let card = Color("YZCard")
    static let line = Color("YZLine")
    static let ink = Color("YZInk")
    static let ink2 = Color("YZInk2")
    static let ink3 = Color("YZInk3")
    static let blue = Color("YZBlue")
    static let blueFill = Color("YZBlueFill")
    static let blueSoft = Color("YZBlueSoft")
    static let blueLine = Color("YZBlueLine")
    static let green = Color("YZGreen")
    static let greenFill = Color("YZGreenFill")
    static let greenSoft = Color("YZGreenSoft")
    static let danger = Color("YZDanger")
    static let dangerSoft = Color("YZDangerSoft")

    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 20
    static let iconRadius: CGFloat = 16
    static let pagePadding: CGFloat = 16
    static let gapGroup: CGFloat = 12
    static let gapInner: CGFloat = 8
    static let rowHeight: CGFloat = 68
    static let iconSize: CGFloat = 40
    static let buttonHeight: CGFloat = 56
    static let pillHeight: CGFloat = 32
    static let pillSmallHeight: CGFloat = 28
    static let tabBottomInset: CGFloat = 112

    static let fontPageTitle = Font.system(size: 34, weight: .bold)
    static let fontSectionTitle = Font.system(size: 22, weight: .bold)
    static let fontHero = Font.system(size: 26, weight: .bold)
    static let fontCardText = Font.system(size: 21, weight: .semibold)
    static let fontRowTitle = Font.system(size: 17, weight: .semibold)
    static let fontBody = Font.system(size: 17, weight: .regular)
    static let fontCaption = Font.system(size: 13, weight: .regular)
    static let fontTag = Font.system(size: 11, weight: .regular)
    static let fontPill = Font.system(size: 13, weight: .semibold)
    static let fontPillSmall = Font.system(size: 12, weight: .semibold)
    static let fontTab = Font.system(size: 11, weight: .semibold)
    static let fontButton = Font.system(size: 17, weight: .semibold)

    static let shadowColor = Color(hex: 0x0F1A2E).opacity(0.05)
    static let shadowRadius: CGFloat = 12
    static let shadowY: CGFloat = 2
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension View {
    func yzCardShadow() -> some View {
        shadow(color: YZTheme.shadowColor, radius: YZTheme.shadowRadius, y: YZTheme.shadowY)
    }
}