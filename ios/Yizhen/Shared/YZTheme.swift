import SwiftUI
import UIKit

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

enum YZThemeRuntime {
    static var fontSize: CGFloat = 18
    static var highContrast = false

    static var scale: CGFloat {
        max(1, fontSize / 18)
    }
}

enum YZTheme {
    static var scale: CGFloat { YZThemeRuntime.scale }
    static var highContrast: Bool { YZThemeRuntime.highContrast }


    static var bg: Color { highContrast ? .white : Color("YZBg") }
    static var card: Color { highContrast ? .white : Color("YZCard") }
    static var line: Color { highContrast ? .black : Color("YZLine") }
    static var ink: Color { highContrast ? .black : Color("YZInk") }
    static var ink2: Color { highContrast ? .black : Color("YZInk2") }
    static var ink3: Color { highContrast ? .black : Color("YZInk3") }
    static var blue: Color { highContrast ? .black : Color("YZBlue") }
    static var blueFill: Color { highContrast ? .white : Color("YZBlueFill") }
    static var blueSoft: Color { highContrast ? .white : Color("YZBlueSoft") }
    static var blueLine: Color { highContrast ? .black : Color("YZBlueLine") }
    static var green: Color { highContrast ? .black : Color("YZGreen") }
    static var greenFill: Color { highContrast ? .white : Color("YZGreenFill") }
    static var greenSoft: Color { highContrast ? .white : Color("YZGreenSoft") }
    static var greenLine: Color { highContrast ? .black : Color("YZGreenLine") }
    static var danger: Color { highContrast ? .black : Color("YZDanger") }
    static var dangerSoft: Color { highContrast ? .white : Color("YZDangerSoft") }
    static var chipIdle: Color { highContrast ? .white : Color("YZChipIdle") }
    static var stepIdle: Color { highContrast ? .white : Color("YZStepIdle") }
    static var stepDoneLine: Color { highContrast ? .black : Color("YZStepDoneLine") }
    static var played: Color { highContrast ? .white : Color("YZPlayed") }
    static var scrim: Color { Color(hex: 0x101418, opacity: highContrast ? 0.22 : 0.36) }
    static var toastBackground: Color { highContrast ? .white : Color(hex: 0x0F1A2E) }
    static var toastForeground: Color { highContrast ? .black : .white }


    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 20
    static let iconRadius: CGFloat = 16
    static let pagePadding: CGFloat = 16
    static let gapGroup: CGFloat = 12
    static let gapInner: CGFloat = 8
    static let iconSize: CGFloat = 40
    static let contentMaxWidth: CGFloat = 430
    static let tabBottomInset: CGFloat = 112
    static let talkBottomInset: CGFloat = 96
    static let tabBarHeight: CGFloat = 64

    static var rowHeight: CGFloat { 68 * min(scale, 1.3) }
    static var buttonHeight: CGFloat { 56 * min(scale, 1.2) }
    static var pillHeight: CGFloat { 32 * min(scale, 1.25) }
    static var pillSmallHeight: CGFloat { 28 * min(scale, 1.25) }

    static var shadowColor: Color {
        highContrast ? .clear : Color(hex: 0x0F1A2E).opacity(0.05)
    }
    static var shadowRadius: CGFloat { highContrast ? 0 : 12 }
    static var shadowY: CGFloat { highContrast ? 0 : 2 }


    static var fontPageTitle: Font {
        font(size: 34, weight: .bold, textStyle: .largeTitle, maxSize: 48)
    }

    static var fontSectionTitle: Font {
        font(size: 22, weight: .bold, textStyle: .title2, maxSize: 32)
    }

    static var fontHero: Font {
        font(size: 26, weight: .bold, textStyle: .title1, maxSize: 38)
    }

    static var fontCardText: Font {
        font(size: 21, weight: .semibold, textStyle: .title3, maxSize: 32)
    }

    static var fontRowTitle: Font {
        font(size: 17, weight: .semibold, textStyle: .body, maxSize: 25)
    }

    static var fontBody: Font {
        font(size: 18, weight: .regular, textStyle: .body, maxSize: 30)
    }

    static var fontCaption: Font {
        font(size: 13, weight: .regular, textStyle: .footnote, maxSize: 19)
    }

    static var fontTag: Font {
        font(size: 11, weight: .regular, textStyle: .caption2, maxSize: 16)
    }

    static var fontPill: Font {
        font(size: 13, weight: .semibold, textStyle: .footnote, maxSize: 20)
    }

    static var fontPillSmall: Font {
        font(size: 12, weight: .semibold, textStyle: .caption, maxSize: 18)
    }

    static var fontTab: Font {
        font(size: 11, weight: .semibold, textStyle: .caption2, maxSize: 15)
    }

    static var fontButton: Font {
        font(size: 17, weight: .semibold, textStyle: .body, maxSize: 25)
    }

    static func font(
        size: CGFloat,
        weight: Font.Weight = .regular,
        textStyle: UIFont.TextStyle = .body,
        maxSize: CGFloat? = nil
    ) -> Font {
        let base = UIFont.systemFont(ofSize: size, weight: uiWeight(weight))
        let scaled = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
        let points = min(scaled.pointSize * scale, maxSize ?? size * 1.8)
        return .system(size: max(size, points), weight: weight)
    }

    static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        if weight == .ultraLight { return .ultraLight }
        if weight == .thin { return .thin }
        if weight == .light { return .light }
        if weight == .semibold { return .semibold }
        if weight == .bold { return .bold }
        if weight == .heavy { return .heavy }
        if weight == .black { return .black }
        if weight == .medium { return .medium }
        return .regular
    }
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

    func yzContentWidth() -> some View {
        frame(maxWidth: YZTheme.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
