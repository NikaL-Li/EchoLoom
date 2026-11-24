import SwiftUI

struct YZTheme {
    let colors: YZColorTokens
    let typography: YZTypographyTokens
    let metrics: YZMetricTokens
    let shadow: YZShadowTokens
    let motion: YZMotionTokens

    static func resolve(scheme: ColorScheme, reduceMotion: Bool) -> YZTheme {
        let colors = YZColorTokens.resolve(scheme)
        return YZTheme(
            colors: colors,
            typography: YZTypographyTokens(),
            metrics: YZMetricTokens(),
            shadow: YZShadowTokens.resolve(colors),
            motion: YZMotionTokens.resolve(reduceMotion: reduceMotion)
        )
    }
}

protocol YZThemeProviding {
    func theme(for scheme: ColorScheme, reduceMotion: Bool) -> YZTheme
}

extension YZThemeProviding {
    func theme(for scheme: ColorScheme) -> YZTheme {
        theme(for: scheme, reduceMotion: false)
    }
}

struct YZPlaceholderThemeProvider: YZThemeProviding {
    func theme(for scheme: ColorScheme, reduceMotion: Bool) -> YZTheme {
        YZTheme.resolve(scheme: scheme, reduceMotion: reduceMotion)
    }
}

private struct YZThemeKey: EnvironmentKey {
    static let defaultValue = YZTheme.resolve(scheme: .light, reduceMotion: false)
}

extension EnvironmentValues {
    var yzTheme: YZTheme {
        get { self[YZThemeKey.self] }
        set { self[YZThemeKey.self] = newValue }
    }
}