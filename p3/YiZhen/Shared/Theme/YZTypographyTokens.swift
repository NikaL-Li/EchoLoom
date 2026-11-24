import SwiftUI
import UIKit

enum YZTextRole: CaseIterable, Hashable {
    case display
    case section
    case cardSentence
    case navTitle
    case body
    case button
    case caption
    case captionStrong
    case micro

    case closeLabel
    case facePill
    case sceneChip
    case dockButton
    case bannerLabel
    case cardLabel
    case statusPill
    case cardAction
    case saySentence
    case sayMeta
    case phaseStepLabel
    case phaseStepNumber
    case phaseTabLabel

    case composerTitle
    case composerClose
    case composerInput
    case composerSend
    case composerNote
}

struct YZTypographyTokens {
    private struct Spec {
        let size: CGFloat
        let weight: Font.Weight
        let uiWeight: UIFont.Weight
        let textStyle: UIFont.TextStyle
        let minSize: CGFloat
        let lineHeight: CGFloat
    }

    init() {}

    private let specs: [YZTextRole: Spec] = [
        .display: Spec(size: 34, weight: .bold, uiWeight: .bold, textStyle: .largeTitle, minSize: 34, lineHeight: 1.2),
        .section: Spec(size: 22, weight: .bold, uiWeight: .bold, textStyle: .title2, minSize: 22, lineHeight: 1.25),
        .cardSentence: Spec(size: 22, weight: .semibold, uiWeight: .semibold, textStyle: .title3, minSize: 22, lineHeight: 1.5),
        .navTitle: Spec(size: 18, weight: .semibold, uiWeight: .semibold, textStyle: .headline, minSize: 16, lineHeight: 1.25),
        .body: Spec(size: 17, weight: .regular, uiWeight: .regular, textStyle: .body, minSize: 17, lineHeight: 1.35),
        .button: Spec(size: 17, weight: .semibold, uiWeight: .semibold, textStyle: .body, minSize: 17, lineHeight: 1.25),
        .caption: Spec(size: 13, weight: .regular, uiWeight: .regular, textStyle: .footnote, minSize: 13, lineHeight: 1.35),
        .captionStrong: Spec(size: 13, weight: .semibold, uiWeight: .semibold, textStyle: .footnote, minSize: 13, lineHeight: 1.35),
        .micro: Spec(size: 11, weight: .regular, uiWeight: .regular, textStyle: .caption2, minSize: 11, lineHeight: 1.35),

        .closeLabel: Spec(size: 15, weight: .semibold, uiWeight: .semibold, textStyle: .body, minSize: 15, lineHeight: 1.25),
        .facePill: Spec(size: 11, weight: .semibold, uiWeight: .semibold, textStyle: .caption2, minSize: 11, lineHeight: 1.2),
        .sceneChip: Spec(size: 12.5, weight: .medium, uiWeight: .medium, textStyle: .footnote, minSize: 12.5, lineHeight: 1.2),
        .dockButton: Spec(size: 15, weight: .bold, uiWeight: .bold, textStyle: .body, minSize: 15, lineHeight: 1.25),
        .bannerLabel: Spec(size: 14, weight: .bold, uiWeight: .bold, textStyle: .subheadline, minSize: 14, lineHeight: 1.3),
        .cardLabel: Spec(size: 12, weight: .medium, uiWeight: .medium, textStyle: .caption, minSize: 12, lineHeight: 1.2),
        .statusPill: Spec(size: 10.5, weight: .semibold, uiWeight: .semibold, textStyle: .caption2, minSize: 10.5, lineHeight: 1.2),
        .cardAction: Spec(size: 11, weight: .regular, uiWeight: .regular, textStyle: .caption2, minSize: 11, lineHeight: 1.2),
        .saySentence: Spec(size: 18, weight: .medium, uiWeight: .medium, textStyle: .body, minSize: 18, lineHeight: 1.35),
        .sayMeta: Spec(size: 12, weight: .medium, uiWeight: .medium, textStyle: .caption, minSize: 12, lineHeight: 1.2),
        .phaseStepLabel: Spec(size: 13, weight: .medium, uiWeight: .medium, textStyle: .footnote, minSize: 13, lineHeight: 1.2),
        .phaseStepNumber: Spec(size: 12, weight: .semibold, uiWeight: .semibold, textStyle: .caption, minSize: 12, lineHeight: 1.2),
        .phaseTabLabel: Spec(size: 14, weight: .medium, uiWeight: .medium, textStyle: .subheadline, minSize: 14, lineHeight: 1.2),

        .composerTitle: Spec(size: 16, weight: .heavy, uiWeight: .heavy, textStyle: .headline, minSize: 16, lineHeight: 1.25),
        .composerClose: Spec(size: 12, weight: .regular, uiWeight: .regular, textStyle: .caption, minSize: 12, lineHeight: 1.2),
        .composerInput: Spec(size: 16, weight: .regular, uiWeight: .regular, textStyle: .body, minSize: 16, lineHeight: 1.5),
        .composerSend: Spec(size: 15, weight: .bold, uiWeight: .bold, textStyle: .body, minSize: 15, lineHeight: 1.25),
        .composerNote: Spec(size: 11, weight: .regular, uiWeight: .regular, textStyle: .caption2, minSize: 11, lineHeight: 1.5)
    ]

    func font(for role: YZTextRole, maxSize: CGFloat? = nil, weight: Font.Weight? = nil) -> Font {
        guard let spec = specs[role] else { return .body }
        let base = UIFont.systemFont(ofSize: spec.size, weight: spec.uiWeight)
        let scaled = UIFontMetrics(forTextStyle: spec.textStyle).scaledFont(for: base)
        let resolved = max(spec.minSize, scaled.pointSize)
        let clamped = maxSize.map { min(resolved, $0) } ?? resolved
        return .system(size: clamped, weight: weight ?? spec.weight)
    }

    func scaledFont(for role: YZTextRole) -> UIFont {
        guard let spec = specs[role] else { return UIFont.systemFont(ofSize: 17) }
        let base = UIFont.systemFont(ofSize: spec.size, weight: spec.uiWeight)
        let scaled = UIFontMetrics(forTextStyle: spec.textStyle).scaledFont(for: base)
        return scaled.pointSize < spec.minSize
            ? UIFont.systemFont(ofSize: spec.minSize, weight: spec.uiWeight)
            : scaled
    }

    func baseSize(for role: YZTextRole) -> CGFloat {
        specs[role]?.size ?? 17
    }

    func lineHeight(for role: YZTextRole) -> CGFloat {
        specs[role]?.lineHeight ?? 1.2
    }

    func lineSpacing(for role: YZTextRole) -> CGFloat {
        let spec = specs[role] ?? specs[.body]!
        return max(0, (spec.lineHeight - 1.2) * spec.size)
    }
}