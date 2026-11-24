import Foundation

enum YZProfileSettingsPersistence {
    private static let themeKey = "yz.appearance.mode"
    private static let fontSizeKey = "yz.typography.fontSize"
    private static let highContrastKey = "yz.display.highContrast"
    private static let textOnlyKey = "yz.voice.textOnly"

    @MainActor
    static func load(into appState: YZAppState) {
        let defaults = UserDefaults.standard

        if let raw = defaults.string(forKey: themeKey),
           let mode = YZThemeMode(rawValue: raw) {
            appState.themeMode = mode
        }

        if let raw = defaults.object(forKey: fontSizeKey) as? Int,
           let size = YZFontSize(rawValue: raw) {
            appState.fontSize = size
        }

        if defaults.object(forKey: highContrastKey) != nil {
            appState.highContrast = defaults.bool(forKey: highContrastKey)
        }

        if defaults.object(forKey: textOnlyKey) != nil {
            appState.textOnly = defaults.bool(forKey: textOnlyKey)
        }
    }

    @MainActor
    static func save(from appState: YZAppState) {
        let defaults = UserDefaults.standard
        defaults.set(appState.themeMode.rawValue, forKey: themeKey)
        defaults.set(appState.fontSize.rawValue, forKey: fontSizeKey)
        defaults.set(appState.highContrast, forKey: highContrastKey)
        defaults.set(appState.textOnly, forKey: textOnlyKey)
    }
}
