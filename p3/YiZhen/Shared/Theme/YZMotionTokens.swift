import SwiftUI

struct YZMotionTokens {
    let reduceMotion: Bool
    let cardEntranceDuration: TimeInterval
    let cardEntranceOffset: CGFloat
    let pressDuration: TimeInterval
    let pressScale: CGFloat
    let segmentSwitchDuration: TimeInterval
    let bannerTransitionDuration: TimeInterval
    let toastDuration: TimeInterval
    let toastOffset: CGFloat
    let recordingGlowEnabled: Bool
    let toastVisibleDuration: TimeInterval
    let composerTransitionDuration: TimeInterval
    let composerReducedDuration: TimeInterval
    let composerDragCloseThreshold: CGFloat

    static func resolve(reduceMotion: Bool) -> YZMotionTokens {
        if reduceMotion {
            return YZMotionTokens(
                reduceMotion: true,
                cardEntranceDuration: 0.08,
                cardEntranceOffset: 0,
                pressDuration: 0,
                pressScale: 1,
                segmentSwitchDuration: 0,
                bannerTransitionDuration: 0,
                toastDuration: 0.08,
                toastOffset: 0,
                recordingGlowEnabled: false,
                toastVisibleDuration: 1.6,
                composerTransitionDuration: 0.08,
                composerReducedDuration: 0.08,
                composerDragCloseThreshold: 40
            )
        }
        return YZMotionTokens(
            reduceMotion: false,
            cardEntranceDuration: 0.18,
            cardEntranceOffset: 8,
            pressDuration: 0.12,
            pressScale: 0.98,
            segmentSwitchDuration: 0.18,
            bannerTransitionDuration: 0.18,
            toastDuration: 0.18,
            toastOffset: 4,
            recordingGlowEnabled: false,
            toastVisibleDuration: 1.6,
            composerTransitionDuration: 0.22,
            composerReducedDuration: 0.08,
            composerDragCloseThreshold: 40
        )
    }

    var cardEntranceAnimation: Animation? {
        reduceMotion ? .linear(duration: cardEntranceDuration) : .easeOut(duration: cardEntranceDuration)
    }

    var pressAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: pressDuration)
    }

    var segmentSwitchAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: segmentSwitchDuration)
    }

    var bannerTransitionAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: bannerTransitionDuration)
    }

    var toastAnimation: Animation {
        reduceMotion ? .linear(duration: toastDuration) : .easeOut(duration: toastDuration)
    }

    var composerAnimation: Animation {
        reduceMotion
            ? .linear(duration: composerReducedDuration)
            : .easeOut(duration: composerTransitionDuration)
    }
}