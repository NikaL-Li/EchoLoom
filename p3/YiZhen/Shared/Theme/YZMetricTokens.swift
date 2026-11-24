import SwiftUI

struct YZRadiusTokens {
    let card: CGFloat = 24
    let button: CGFloat = 20
    let capsuleScene: CGFloat = 16
    let capsuleFace: CGFloat = 20
    let close: CGFloat = 24
    let iconTile: CGFloat = 16
    let edgeBar: CGFloat = 2
    let segmentContainer: CGFloat = 16
    let segmentThumb: CGFloat = 14
    let toast: CGFloat = 20

    let sceneCapsuleFull: CGFloat = 999
    let facePill: CGFloat = 20
    let dockContainer: CGFloat = 24
    let dockButton: CGFloat = 20
    let cardAction: CGFloat = 8
    let statusPill: CGFloat = 999

    let sheet: CGFloat = 24
    let composerClose: CGFloat = 10
    let composerInput: CGFloat = 14
    let sheetGrip: CGFloat = 2
}

struct YZSpacingTokens {
    let pageHorizontal: CGFloat = 14
    let cardPadding: CGFloat = 16
    let cardGap: CGFloat = 12
    let buttonGap: CGFloat = 8
    let topBarContent: CGFloat = 60
    let topBarVertical: CGFloat = 6
    let sceneGap: CGFloat = 8
    let phaseGap: CGFloat = 8
    let headerSceneGap: CGFloat = 8
    let scenePhaseGap: CGFloat = 8
    let phaseSegmentGap: CGFloat = 12
    let segmentContentGap: CGFloat = 12
    let bottomSafeGap: CGFloat = 8
    let bottomContentGap: CGFloat = 12
    let iconTextGap: CGFloat = 8
    let iconTextGapCompact: CGFloat = 4

    let talkBarTop: CGFloat = 10
    let talkBarBottom: CGFloat = 8
    let chipsTop: CGFloat = 8
    let subNavTop: CGFloat = 2
    let stepperVertical: CGFloat = 12
    let dockInset: CGFloat = 10
    let dockContainerPadding: CGFloat = 8
    let chipPaddingH: CGFloat = 14
    let facePaddingH: CGFloat = 9
    let closePaddingH: CGFloat = 16
    let cardLabelGap: CGFloat = 7
    let cardFootTop: CGFloat = 10
    let pillPaddingV: CGFloat = 2
    let pillPaddingH: CGFloat = 8
    let sayRowPaddingV: CGFloat = 12
    let sayRowPaddingH: CGFloat = 16
    let tabItemGap: CGFloat = 18

    let sheetPaddingH: CGFloat = 16
    let sheetPaddingTop: CGFloat = 9
    let sheetPaddingBottom: CGFloat = 18
    let sheetItemGap: CGFloat = 10
    let composerInputPaddingV: CGFloat = 11
    let composerInputPaddingH: CGFloat = 12
}

struct YZSizeTokens {
    let closeHeight: CGFloat = 48
    let closeMinWidth: CGFloat = 48
    let faceHeight: CGFloat = 28
    let sceneHeight: CGFloat = 32
    let phaseRowMinHeight: CGFloat = 24
    let segmentHeight: CGFloat = 32
    let segmentThumbHeight: CGFloat = 28
    let buttonHeight: CGFloat = 56
    let bannerMinHeight: CGFloat = 48
    let iconTile: CGFloat = 40
    let actionIcon: CGFloat = 18
    let actionIconCompact: CGFloat = 14
    let edgeBarWidth: CGFloat = 4
    let hitTarget: CGFloat = 44
    let maxContentWidth: CGFloat = 430

    let stepperDot: CGFloat = 22
    let stepperLine: CGFloat = 2
    let stepperItemMinWidth: CGFloat = 76
    let stepperDotLabelGap: CGFloat = 6
    let cardActionHeight: CGFloat = 30
    let cardStroke: CGFloat = 1
    let pillDot: CGFloat = 5
    let tabIndicator: CGFloat = 2
    let sayRowMinHeight: CGFloat = 72
    let sayIcon: CGFloat = 24
    let dockMaxWidth: CGFloat = 430
    let contentBottomReserve: CGFloat = 82
    let contentBottomReserveEmergency: CGFloat = 138

    let sheetGripWidth: CGFloat = 38
    let sheetGripHeight: CGFloat = 4
    let composerCloseHeight: CGFloat = 32
    let composerInputMinHeight: CGFloat = 88
    let composerInputMaxHeight: CGFloat = 150
    let composerInputStroke: CGFloat = 1.5
    let sheetMaxHeightRatio: CGFloat = 0.6
    let sheetTopInset: CGFloat = 24
    let composerMaxLength: Int = 500
}

struct YZMetricTokens {
    let radius = YZRadiusTokens()
    let spacing = YZSpacingTokens()
    let size = YZSizeTokens()
}