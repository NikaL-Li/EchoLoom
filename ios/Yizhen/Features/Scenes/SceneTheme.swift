import SwiftUI

enum SceneTheme {
    static func bg(_ scheme: ColorScheme) -> Color { YZTheme.bg }
    static func card(_ scheme: ColorScheme) -> Color { YZTheme.card }
    static func ink(_ scheme: ColorScheme) -> Color { YZTheme.ink }
    static func ink2(_ scheme: ColorScheme) -> Color { YZTheme.ink2 }
    static func ink3(_ scheme: ColorScheme) -> Color { YZTheme.ink3 }
    static func line(_ scheme: ColorScheme) -> Color { YZTheme.line }
    static func primary(_ scheme: ColorScheme) -> Color { YZTheme.blue }
    static func primaryFill(_ scheme: ColorScheme) -> Color { YZTheme.blueFill }
    static func soft(_ scheme: ColorScheme) -> Color { YZTheme.blueSoft }
    static func softLine(_ scheme: ColorScheme) -> Color { YZTheme.blueLine }
    static func chipBackground(_ scheme: ColorScheme) -> Color { YZTheme.chipIdle }
    static func chipInk(_ scheme: ColorScheme) -> Color { YZTheme.ink2 }
    static func stepDotBackground(_ scheme: ColorScheme) -> Color { YZTheme.stepIdle }
    static func stepDoneLine(_ scheme: ColorScheme) -> Color { YZTheme.stepDoneLine }
    static func playedBackground(_ scheme: ColorScheme) -> Color { YZTheme.played }

    static var onPrimary: Color { .white }

    static func chipSelectedBackground(_ scheme: ColorScheme) -> Color {
        YZTheme.highContrast ? .black : YZTheme.blueFill
    }
    static var outline: Color { YZTheme.highContrast ? .black : .clear }
}
