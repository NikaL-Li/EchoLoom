import XCTest
import SwiftUI
import UIKit
@testable import YiZhen

final class ThemeTokenTests: XCTestCase {
    private func rgba(of color: Color) -> [CGFloat] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        _ = UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha]
    }

    private func alpha(of color: Color) -> CGFloat {
        rgba(of: color)[3]
    }

    private func assertColor(_ color: Color, _ hex: UInt32, alpha expectedAlpha: CGFloat = 1) {
        let components = rgba(of: color)
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        XCTAssertEqual(components[0], red, accuracy: 0.005)
        XCTAssertEqual(components[1], green, accuracy: 0.005)
        XCTAssertEqual(components[2], blue, accuracy: 0.005)
        XCTAssertEqual(components[3], expectedAlpha, accuracy: 0.01)
    }

    func testLightSemanticColorsAreOpaque() {
        let colors = YZColorTokens.light
        let required: [Color] = [
            colors.background, colors.surface, colors.separator, colors.textPrimary,
            colors.textSecondary, colors.textWeak, colors.accent, colors.accentFill,
            colors.accentSoft, colors.accentStroke, colors.onAccent, colors.success,
            colors.successSoft, colors.danger, colors.dangerSoft, colors.dangerStroke,
            colors.toastSurface, colors.toastText, colors.sceneChipIdle, colors.stepIdle,
            colors.stepDoneLine, colors.secondaryButtonStroke, colors.dangerSolid,
            colors.pillOkText, colors.pillFailText, colors.pillOkBg, colors.pillFailBg,
            colors.blueLine, colors.greenLine, colors.sheetGrip, colors.inputSurface,
            colors.inputStroke, colors.sendDisabledFill
        ]
        for color in required {
            XCTAssertGreaterThanOrEqual(alpha(of: color), 1, "浅色语义色透明度不足")
        }
    }

    func testDarkSemanticColorsAreOpaque() {
        let colors = YZColorTokens.dark
        let required: [Color] = [
            colors.background, colors.surface, colors.separator, colors.textPrimary,
            colors.textSecondary, colors.textWeak, colors.accent, colors.accentFill,
            colors.accentSoft, colors.accentStroke, colors.onAccent, colors.success,
            colors.successSoft, colors.danger, colors.dangerSoft, colors.dangerStroke,
            colors.toastSurface, colors.toastText, colors.sceneChipIdle, colors.stepIdle,
            colors.stepDoneLine, colors.secondaryButtonStroke, colors.dangerSolid,
            colors.pillOkText, colors.pillFailText, colors.pillOkBg, colors.pillFailBg,
            colors.blueLine, colors.greenLine, colors.sheetGrip, colors.inputSurface,
            colors.inputStroke, colors.sendDisabledFill
        ]
        for color in required {
            XCTAssertGreaterThanOrEqual(alpha(of: color), 1, "深色语义色透明度不足")
        }
    }

    func testNewColorValuesMatchDesign() {
        assertColor(YZColorTokens.light.sceneChipIdle, 0xF4F6FB)
        assertColor(YZColorTokens.light.stepIdle, 0xE4E9F2)
        assertColor(YZColorTokens.light.stepDoneLine, 0x8FA8FF)
        assertColor(YZColorTokens.light.secondaryButtonStroke, 0xD9E4F8)
        assertColor(YZColorTokens.light.dangerSolid, 0xD6402B)
        assertColor(YZColorTokens.dark.dangerSolid, 0xB93220)
        assertColor(YZColorTokens.light.pillFailText, 0xB93220)
        assertColor(YZColorTokens.dark.pillFailText, 0xFF7466)
        assertColor(YZColorTokens.light.sheetGrip, 0xE3EAF7)
        assertColor(YZColorTokens.dark.sheetGrip, 0x2C3F63)
        assertColor(YZColorTokens.light.inputSurface, 0xFFFFFF)
        assertColor(YZColorTokens.dark.inputSurface, 0x0B1220)
        assertColor(YZColorTokens.light.inputStroke, 0xDDE7FA)
        assertColor(YZColorTokens.light.sendDisabledFill, 0xEEF3FF)
        assertColor(YZColorTokens.dark.sendDisabledFill, 0x1B2A4A)
    }

    func testScrimAlpha() {
        XCTAssertEqual(alpha(of: YZColorTokens.light.scrim), 0.32, accuracy: 0.01)
        XCTAssertEqual(alpha(of: YZColorTokens.dark.scrim), 0.40, accuracy: 0.01)
    }

    func testGlassTintAlpha() {
        XCTAssertEqual(alpha(of: YZColorTokens.light.glassTint), 0.90, accuracy: 0.01)
        XCTAssertEqual(alpha(of: YZColorTokens.dark.glassTint), 0.92, accuracy: 0.01)
        XCTAssertEqual(alpha(of: YZColorTokens.light.dockGlassTint), 0.92, accuracy: 0.01)
        XCTAssertEqual(alpha(of: YZColorTokens.dark.dockGlassTint), 0.94, accuracy: 0.01)
    }

    func testTypographyRolesAreComplete() {
        let typography = YZTypographyTokens()
        for role in YZTextRole.allCases {
            XCTAssertGreaterThan(typography.baseSize(for: role), 0, "\(role) 缺少字号")
        }
        XCTAssertEqual(typography.baseSize(for: .closeLabel), 15)
        XCTAssertEqual(typography.baseSize(for: .facePill), 11)
        XCTAssertEqual(typography.baseSize(for: .sceneChip), 12.5)
        XCTAssertEqual(typography.baseSize(for: .dockButton), 15)
        XCTAssertEqual(typography.baseSize(for: .bannerLabel), 14)
        XCTAssertEqual(typography.baseSize(for: .cardLabel), 12)
        XCTAssertEqual(typography.baseSize(for: .statusPill), 10.5)
        XCTAssertEqual(typography.baseSize(for: .cardAction), 11)
        XCTAssertEqual(typography.baseSize(for: .saySentence), 18)
        XCTAssertEqual(typography.baseSize(for: .sayMeta), 12)
        XCTAssertEqual(typography.baseSize(for: .phaseStepLabel), 13)
        XCTAssertEqual(typography.baseSize(for: .phaseStepNumber), 12)
        XCTAssertEqual(typography.baseSize(for: .phaseTabLabel), 14)
        XCTAssertEqual(typography.baseSize(for: .composerTitle), 16)
        XCTAssertEqual(typography.baseSize(for: .composerClose), 12)
        XCTAssertEqual(typography.baseSize(for: .composerInput), 16)
        XCTAssertEqual(typography.baseSize(for: .composerSend), 15)
        XCTAssertEqual(typography.baseSize(for: .composerNote), 11)
        XCTAssertEqual(typography.lineHeight(for: .composerInput), 1.5, accuracy: 0.001)
        XCTAssertEqual(typography.lineHeight(for: .composerNote), 1.5, accuracy: 0.001)
    }

    func testCardSentenceKeepsTwentyTwoAndLineHeightOnePointFive() {
        let typography = YZTypographyTokens()
        XCTAssertEqual(typography.baseSize(for: .cardSentence), 22)
        XCTAssertEqual(typography.lineHeight(for: .cardSentence), 1.5, accuracy: 0.001)
        XCTAssertEqual(typography.lineSpacing(for: .cardSentence), 6.6, accuracy: 0.05)
    }

    func testMetricTokensMatchSpec() {
        let metrics = YZMetricTokens()
        XCTAssertEqual(metrics.radius.card, 24)
        XCTAssertEqual(metrics.radius.button, 20)
        XCTAssertEqual(metrics.radius.facePill, 20)
        XCTAssertEqual(metrics.radius.dockContainer, 24)
        XCTAssertEqual(metrics.radius.dockButton, 20)
        XCTAssertEqual(metrics.radius.cardAction, 8)
        XCTAssertEqual(metrics.spacing.pageHorizontal, 14)
        XCTAssertEqual(metrics.spacing.cardPadding, 16)
        XCTAssertEqual(metrics.spacing.cardGap, 12)
        XCTAssertEqual(metrics.spacing.buttonGap, 8)
        XCTAssertEqual(metrics.spacing.talkBarTop, 10)
        XCTAssertEqual(metrics.spacing.talkBarBottom, 8)
        XCTAssertEqual(metrics.spacing.chipsTop, 8)
        XCTAssertEqual(metrics.spacing.subNavTop, 2)
        XCTAssertEqual(metrics.spacing.dockInset, 10)
        XCTAssertEqual(metrics.spacing.dockContainerPadding, 8)
        XCTAssertEqual(metrics.size.buttonHeight, 56)
        XCTAssertEqual(metrics.size.closeHeight, 48)
        XCTAssertEqual(metrics.size.closeMinWidth, 48)
        XCTAssertEqual(metrics.size.faceHeight, 28)
        XCTAssertEqual(metrics.size.sceneHeight, 32)
        XCTAssertEqual(metrics.size.hitTarget, 44)
        XCTAssertEqual(metrics.size.maxContentWidth, 430)
        XCTAssertEqual(metrics.size.stepperDot, 22)
        XCTAssertEqual(metrics.size.stepperLine, 2)
        XCTAssertEqual(metrics.size.stepperItemMinWidth, 76)
        XCTAssertEqual(metrics.size.cardActionHeight, 30)
        XCTAssertEqual(metrics.size.sayRowMinHeight, 72)
        XCTAssertEqual(metrics.size.dockMaxWidth, 430)
        XCTAssertEqual(metrics.size.contentBottomReserve, 82)
        XCTAssertEqual(metrics.size.contentBottomReserveEmergency, 138)
        XCTAssertEqual(metrics.radius.sheet, 24)
        XCTAssertEqual(metrics.radius.composerClose, 10)
        XCTAssertEqual(metrics.radius.composerInput, 14)
        XCTAssertEqual(metrics.size.sheetGripWidth, 38)
        XCTAssertEqual(metrics.size.sheetGripHeight, 4)
        XCTAssertEqual(metrics.size.composerCloseHeight, 32)
        XCTAssertEqual(metrics.size.composerInputMinHeight, 88)
        XCTAssertEqual(metrics.size.composerInputMaxHeight, 150)
        XCTAssertEqual(metrics.size.composerInputStroke, 1.5)
        XCTAssertEqual(metrics.size.sheetMaxHeightRatio, 0.6)
        XCTAssertEqual(metrics.size.sheetTopInset, 24)
        XCTAssertEqual(metrics.spacing.sheetPaddingH, 16)
        XCTAssertEqual(metrics.spacing.sheetPaddingTop, 9)
        XCTAssertEqual(metrics.spacing.sheetPaddingBottom, 18)
        XCTAssertEqual(metrics.spacing.sheetItemGap, 10)
        XCTAssertEqual(metrics.spacing.composerInputPaddingV, 11)
        XCTAssertEqual(metrics.spacing.composerInputPaddingH, 12)
    }

    func testLightThemeHasVisibleCardShadow() {
        let theme = YZTheme.resolve(scheme: .light, reduceMotion: false)
        XCTAssertGreaterThan(theme.shadow.card.radius, 0)
        XCTAssertEqual(theme.shadow.card.y, 2)
        XCTAssertGreaterThan(theme.shadow.closePill.radius, 0)
    }

    func testDarkThemeOnlyDockShadowIsVisible() {
        let theme = YZTheme.resolve(scheme: .dark, reduceMotion: false)
        XCTAssertEqual(theme.shadow.card.radius, 0)
        XCTAssertEqual(theme.shadow.secondaryButton.radius, 0)
        XCTAssertEqual(theme.shadow.segmentThumb.radius, 0)
        XCTAssertEqual(theme.shadow.toast.radius, 0)
        XCTAssertEqual(theme.shadow.talkBar.radius, 0)
        XCTAssertEqual(theme.shadow.closePill.radius, 0)
        XCTAssertEqual(theme.shadow.dockPrimary.radius, 0)
        XCTAssertEqual(theme.shadow.banner.radius, 0)
        XCTAssertEqual(theme.shadow.dockUp.radius, 30)
        XCTAssertEqual(theme.shadow.dockUp.y, -10)
        XCTAssertEqual(theme.shadow.sheetUp.radius, 30)
        XCTAssertEqual(theme.shadow.sheetUp.y, -10)
    }

    func testReduceMotionZeroesOffsetAndScale() {
        let theme = YZTheme.resolve(scheme: .light, reduceMotion: true)
        XCTAssertTrue(theme.motion.reduceMotion)
        XCTAssertEqual(theme.motion.cardEntranceOffset, 0)
        XCTAssertEqual(theme.motion.pressScale, 1)
        XCTAssertLessThanOrEqual(theme.motion.cardEntranceDuration, 0.1)
    }

    func testRecordingGlowIsDisabled() {
        let light = YZTheme.resolve(scheme: .light, reduceMotion: false)
        let dark = YZTheme.resolve(scheme: .dark, reduceMotion: false)
        XCTAssertFalse(light.motion.recordingGlowEnabled)
        XCTAssertFalse(dark.motion.recordingGlowEnabled)
    }

    func testWeakTextFallbackUsesSecondaryInLightMode() {
        let colors = YZColorTokens.light
        XCTAssertEqual(rgba(of: colors.weakTextOnSurface), rgba(of: colors.textSecondary))
        XCTAssertEqual(rgba(of: YZColorTokens.dark.weakTextOnSurface), rgba(of: YZColorTokens.dark.textWeak))
    }

    func testSemanticAliases() {
        let light = YZColorTokens.light
        XCTAssertEqual(rgba(of: light.closeLabel), rgba(of: light.accent))
        XCTAssertEqual(rgba(of: light.bannerBg), rgba(of: light.dangerSolid))
        XCTAssertEqual(rgba(of: light.pillPlainBg), rgba(of: light.background))
        XCTAssertEqual(rgba(of: YZColorTokens.dark.closeLabel), rgba(of: YZColorTokens.dark.textSecondary))
    }
}