import SwiftUI

enum YZProfileStyle {
    static var pageBackground: Color { YZTheme.bg }
    static var cardBackground: Color { YZTheme.card }
    static var textPrimary: Color { YZTheme.ink }
    static var textSecondary: Color { YZTheme.ink2 }
    static var textTertiary: Color { YZTheme.ink3 }
    static var separator: Color { YZTheme.line }
    static var primary: Color { YZTheme.blue }
    static var primaryFill: Color { YZTheme.blueFill }
    static var primarySoft: Color { YZTheme.blueSoft }
    static var mutedSurface: Color { YZTheme.bg }
    static var success: Color { YZTheme.green }
    static var danger: Color { YZTheme.danger }
}

enum YZProfileFont {
    static var pageTitle: Font { YZTheme.fontPageTitle }
    static var rowTitle: Font { YZTheme.fontRowTitle }
    static var body: Font { YZTheme.fontBody }
    static var caption: Font { YZTheme.fontCaption }
    static var tag: Font { YZTheme.fontTag }
    static let avatar = Font.system(size: 22, weight: .semibold)
}

enum YZProfileCopy {
    static let pageTitle = "我的"
    static let userName = "本机用户"
    static let userSubtitle = "记录只保存在这台设备"
    static let avatarInitial = "本"
    static let phrases = "我的常用语"
    static let guide = "使用指南"
    static let guideSubtitle = "了解译诊怎么用"
    static let appearance = "外观"
    static let appearanceSystem = "跟随系统"
    static let appearanceLight = "浅色"
    static let appearanceDark = "深色"
    static let appearanceNote = "跟随系统时，会随设备的明暗自动切换"
    static let textOnly = "全程用文字"
    static let textOnlyNote = "打开后不调用任何麦克风"
    static let fontSize = "字号"
    static let highContrast = "高对比"

    static let appearanceOptions = [
        appearanceSystem,
        appearanceLight,
        appearanceDark
    ]

    static func title(for mode: YZThemeMode) -> String {
        switch mode {
        case .system:
            return appearanceSystem
        case .light:
            return appearanceLight
        case .dark:
            return appearanceDark
        }
    }

    static func index(for mode: YZThemeMode) -> Int {
        switch mode {
        case .system:
            return 0
        case .light:
            return 1
        case .dark:
            return 2
        }
    }

    static func mode(for index: Int) -> YZThemeMode {
        switch index {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return .system
        }
    }

    static func title(for size: YZFontSize) -> String {
        "\(size.rawValue)"
    }
}
