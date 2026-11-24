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

/// 运行时主题参数：由 RootView 根据 AppState 写入，Theme 读它生成全局值。
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
    static var danger: Color { highContrast ? .black : Color("YZDanger") }
    static var dangerSoft: Color { highContrast ? .white : Color("YZDangerSoft") }

    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 20
    static let iconRadius: CGFloat = 16
    static let pagePadding: CGFloat = 16
    static let gapGroup: CGFloat = 12
    static let gapInner: CGFloat = 8
    static let iconSize: CGFloat = 40
    static let tabBottomInset: CGFloat = 112

    static var rowHeight: CGFloat { 68 * min(scale, 1.3) }
    static var buttonHeight: CGFloat { 56 * min(scale, 1.2) }
    static var pillHeight: CGFloat { 32 * min(scale, 1.25) }
    static var pillSmallHeight: CGFloat { 28 * min(scale, 1.25) }

    static var fontPageTitle: Font {
        .system(size: 34 * min(scale, 1.5), weight: .bold)
    }

    static var fontSectionTitle: Font {
        .system(size: 22 * min(scale, 1.4), weight: .bold)
    }

    static var fontHero: Font {
        .system(size: 26 * min(scale, 1.5), weight: .bold)
    }

    static var fontCardText: Font {
        .system(size: 21 * min(scale, 1.5), weight: .semibold)
    }

    static var fontRowTitle: Font {
        .system(size: 17 * scale, weight: .semibold)
    }

    static var fontBody: Font {
        .system(size: 18 * scale, weight: .regular)
    }

    static var fontCaption: Font {
        .system(size: 13 * scale, weight: .regular)
    }

    static var fontTag: Font {
        .system(size: 11 * scale, weight: .regular)
    }

    static var fontPill: Font {
        .system(size: 13 * min(scale, 1.4), weight: .semibold)
    }

    static var fontPillSmall: Font {
        .system(size: 12 * min(scale, 1.4), weight: .semibold)
    }

    static var fontTab: Font {
        .system(size: 11 * min(scale, 1.2), weight: .semibold)
    }

    static var fontButton: Font {
        .system(size: 17 * min(scale, 1.4), weight: .semibold)
    }

    static var shadowColor: Color {
        highContrast ? .clear : Color(hex: 0x0F1A2E).opacity(0.05)
    }

    static var shadowRadius: CGFloat { highContrast ? 0 : 12 }
    static var shadowY: CGFloat { highContrast ? 0 : 2 }
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