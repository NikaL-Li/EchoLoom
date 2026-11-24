import SwiftUI

enum SceneTheme {
    static func bg(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x0B1220 : 0xF2F4F8)
    }

    static func card(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x121D30 : 0xFFFFFF)
    }

    static func ink(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0xF2F5FA : 0x0F1A2E)
    }

    static func ink2(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0xB9C4D4 : 0x475467)
    }

    static func ink3(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x7C899D : 0x98A2B3)
    }

    static func line(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x223047 : 0xEDF0F5)
    }

    static func primary(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x6F8DFF : 0x1B41C8)
    }

    static func primaryFill(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x2F5BE0 : 0x1B41C8)
    }

    static func soft(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x1B2A4A : 0xE8EDFB)
    }

    static func softLine(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x2C3F63 : 0xD9E2F7)
    }

    static func chipBackground(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x121D30 : 0xF4F6FB)
    }

    static func chipInk(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0xB9C4D4 : 0x475467)
    }

    static func stepDotBackground(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x223047 : 0xE4E9F2)
    }

    static func stepDoneLine(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x3F5FBF : 0x8FA8FF)
    }

    static func playedBackground(_ scheme: ColorScheme) -> Color {
        rgb(scheme == .dark ? 0x1B2A4A : 0xF2F6FF)
    }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}