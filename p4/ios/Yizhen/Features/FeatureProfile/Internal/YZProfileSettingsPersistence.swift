import Foundation
import SwiftUI

/// P1 `YZAppState` 四项目的 UserDefaults 持久化；只负责存取，不改变全局样式。
enum YZProfileSettingsPersistence {
    private static let themeKey = "yz.appearance.mode"
    private static let fontSizeKey = "yz.typography.fontSize"
    private static let highContrastKey = "yz.display.highContrast"
    private static let textOnlyKey = "yz.voice.textOnly"

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

    static func save(from appState: YZAppState) {
        let defaults = UserDefaults.standard
        defaults.set(appState.themeMode.rawValue, forKey: themeKey)
        defaults.set(appState.fontSize.rawValue, forKey: fontSizeKey)
        defaults.set(appState.highContrast, forKey: highContrastKey)
        defaults.set(appState.textOnly, forKey: textOnlyKey)
    }
}

struct YZProfileSettingsPersistenceModifier: ViewModifier {
    let appState: YZAppState

    func body(content: Content) -> some View {
        YZThemeRuntime.fontSize = CGFloat(appState.fontSize.rawValue)
        YZThemeRuntime.highContrast = appState.highContrast

        return content
            .id("\(appState.fontSize.rawValue)-\(appState.highContrast)")
            .onChange(of: appState.themeMode) { _, _ in save() }
            .onChange(of: appState.fontSize) { _, _ in save() }
            .onChange(of: appState.highContrast) { _, _ in save() }
            .onChange(of: appState.textOnly) { _, _ in save() }
    }

    private func save() {
        YZProfileSettingsPersistence.save(from: appState)
    }
}