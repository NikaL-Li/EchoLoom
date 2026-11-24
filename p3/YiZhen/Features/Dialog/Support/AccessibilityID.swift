import Foundation

enum AccessibilityID {
    static let close = "dialog.close"
    static let faceToFace = "dialog.faceToFace"
    static let title = "dialog.title"
    static let talkBar = "dialog.talkbar"
    static let dock = "dialog.dock"

    static func scene(_ id: String) -> String { "dialog.scene.\(id)" }
    static func phase(_ id: String) -> String { "dialog.phase.\(id)" }
    static func segment(_ view: YZDialogView) -> String { "dialog.segment.\(view.rawValue)" }
    static func message(_ id: String) -> String { "dialog.message.\(id)" }
    static func replay(_ id: String) -> String { "dialog.message.\(id).replay" }
    static func copy(_ id: String) -> String { "dialog.message.\(id).copy" }

    static let empty = "dialog.empty"
    static let phraseList = "dialog.phrase.list"
    static let phraseEmpty = "dialog.phrase.empty"
    static let phraseFooter = "dialog.phrase.footer"
    static func phraseRow(_ id: String) -> String { "dialog.phrase.row.\(id)" }

    static let composer = "dialog.composer"
    static let composerTitle = "dialog.composer.title"
    static let composerClose = "dialog.composer.close"
    static let composerInput = "dialog.composer.input"
    static let composerSend = "dialog.composer.send"
    static let composerNote = "dialog.composer.note"
    static let composerGrip = "dialog.composer.grip"

    static let actionListen = "dialog.action.listen"
    static let actionSpeak = "dialog.action.speak"
    static let actionFullScreen = "dialog.action.fullscreen"
    static let emergencyBanner = "dialog.emergencyBanner"
    static let toast = "dialog.toast"
}