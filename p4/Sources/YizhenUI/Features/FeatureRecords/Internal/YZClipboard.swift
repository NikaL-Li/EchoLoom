import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum YZClipboard {
    @MainActor
    @discardableResult
    static func copy(_ text: String) -> Bool {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        return true
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
        #else
        return false
        #endif
    }
}