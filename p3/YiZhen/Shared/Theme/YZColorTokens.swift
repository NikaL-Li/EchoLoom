import SwiftUI

struct YZColorTokens {
    let isDark: Bool
    let background: Color
    let surface: Color
    let separator: Color
    let textPrimary: Color
    let textSecondary: Color
    let textWeak: Color
    let accent: Color
    let accentFill: Color
    let accentSoft: Color
    let accentStroke: Color
    let onAccent: Color
    let success: Color
    let successSoft: Color
    let danger: Color
    let dangerSoft: Color
    let dangerStroke: Color
    let glassTint: Color
    let dockGlassTint: Color
    let shadowColor: Color
    let toastSurface: Color
    let toastText: Color

    let sceneChipIdle: Color
    let stepIdle: Color
    let stepDoneLine: Color
    let secondaryButtonStroke: Color
    let dangerSolid: Color
    let pillOkText: Color
    let pillFailText: Color
    let pillOkBg: Color
    let pillFailBg: Color
    let blueLine: Color
    let greenLine: Color

    let sheetGrip: Color
    let inputSurface: Color
    let inputStroke: Color
    let sendDisabledFill: Color
    let scrim: Color

    var weakTextOnSurface: Color {
        isDark ? textWeak : textSecondary
    }

    var closeLabel: Color { isDark ? textSecondary : accent }
    var chipSelectedBg: Color { accentFill }
    var chipSelectedText: Color { onAccent }
    var bannerBg: Color { dangerSolid }
    var bannerText: Color { onAccent }
    var pillPlainBg: Color { background }
    var pillPlainText: Color { textSecondary }
    var cardLabelText: Color { textWeak }
    var cardActionText: Color { textWeak }
    var sayRowIcon: Color { textWeak }
    var sayMetaText: Color { textWeak }
    var composerSecondaryText: Color { isDark ? textWeak : textSecondary }

    static func resolve(_ scheme: ColorScheme) -> YZColorTokens {
        scheme == .dark ? .dark : .light
    }

    static let light = YZColorTokens(
        isDark: false,
        background: Color(yzHex: 0xF2F4F8),
        surface: Color(yzHex: 0xFFFFFF),
        separator: Color(yzHex: 0xEDF0F5),
        textPrimary: Color(yzHex: 0x0F1A2E),
        textSecondary: Color(yzHex: 0x475467),
        textWeak: Color(yzHex: 0x98A2B3),
        accent: Color(yzHex: 0x1B41C8),
        accentFill: Color(yzHex: 0x1B41C8),
        accentSoft: Color(yzHex: 0xE8EDFB),
        accentStroke: Color(yzHex: 0xD9E2F7),
        onAccent: Color(yzHex: 0xFFFFFF),
        success: Color(yzHex: 0x12796B),
        successSoft: Color(yzHex: 0xE3F2EE),
        danger: Color(yzHex: 0xD6402B),
        dangerSoft: Color(yzHex: 0xFDECEA),
        dangerStroke: Color(yzHex: 0xF3C4BE),
        glassTint: Color(yzHex: 0xFFFFFF, opacity: 0.90),
        dockGlassTint: Color(yzHex: 0xFFFFFF, opacity: 0.92),
        shadowColor: Color(yzHex: 0x0F1A2E, opacity: 0.05),
        toastSurface: Color(yzHex: 0x0F1A2E),
        toastText: Color(yzHex: 0xFFFFFF),
        sceneChipIdle: Color(yzHex: 0xF4F6FB),
        stepIdle: Color(yzHex: 0xE4E9F2),
        stepDoneLine: Color(yzHex: 0x8FA8FF),
        secondaryButtonStroke: Color(yzHex: 0xD9E4F8),
        dangerSolid: Color(yzHex: 0xD6402B),
        pillOkText: Color(yzHex: 0x0A5C50),
        pillFailText: Color(yzHex: 0xB93220),
        pillOkBg: Color(yzHex: 0xE3F2EE),
        pillFailBg: Color(yzHex: 0xFDECEA),
        blueLine: Color(yzHex: 0xD9E2F7),
        greenLine: Color(yzHex: 0xCFE6E1),
        sheetGrip: Color(yzHex: 0xE3EAF7),
        inputSurface: Color(yzHex: 0xFFFFFF),
        inputStroke: Color(yzHex: 0xDDE7FA),
        sendDisabledFill: Color(yzHex: 0xEEF3FF),
        scrim: Color(yzHex: 0x101418, opacity: 0.32)
    )

    static let dark = YZColorTokens(
        isDark: true,
        background: Color(yzHex: 0x0B1220),
        surface: Color(yzHex: 0x121D30),
        separator: Color(yzHex: 0x223047),
        textPrimary: Color(yzHex: 0xF2F5FA),
        textSecondary: Color(yzHex: 0xB9C4D4),
        textWeak: Color(yzHex: 0x7C899D),
        accent: Color(yzHex: 0x6F8DFF),
        accentFill: Color(yzHex: 0x2F5BE0),
        accentSoft: Color(yzHex: 0x1B2A4A),
        accentStroke: Color(yzHex: 0x2C3F63),
        onAccent: Color(yzHex: 0xFFFFFF),
        success: Color(yzHex: 0x3DD6C0),
        successSoft: Color(yzHex: 0x10352F),
        danger: Color(yzHex: 0xFF7466),
        dangerSoft: Color(yzHex: 0x3A1D1B),
        dangerStroke: Color(yzHex: 0x6B2B26),
        glassTint: Color(yzHex: 0x121D30, opacity: 0.92),
        dockGlassTint: Color(yzHex: 0x121D30, opacity: 0.94),
        shadowColor: Color.clear,
        toastSurface: Color(yzHex: 0xF2F5FA),
        toastText: Color(yzHex: 0x0F1A2E),
        sceneChipIdle: Color(yzHex: 0x121D30),
        stepIdle: Color(yzHex: 0x223047),
        stepDoneLine: Color(yzHex: 0x2F5BE0),
        secondaryButtonStroke: Color(yzHex: 0x223047),
        dangerSolid: Color(yzHex: 0xB93220),
        pillOkText: Color(yzHex: 0x3DD6C0),
        pillFailText: Color(yzHex: 0xFF7466),
        pillOkBg: Color(yzHex: 0x10352F),
        pillFailBg: Color(yzHex: 0x3A1D1B),
        blueLine: Color(yzHex: 0x2C3F63),
        greenLine: Color(yzHex: 0x1E4A43),
        sheetGrip: Color(yzHex: 0x2C3F63),
        inputSurface: Color(yzHex: 0x0B1220),
        inputStroke: Color(yzHex: 0x223047),
        sendDisabledFill: Color(yzHex: 0x1B2A4A),
        scrim: Color(yzHex: 0x101418, opacity: 0.40)
    )
}

extension Color {
    init(yzHex hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}