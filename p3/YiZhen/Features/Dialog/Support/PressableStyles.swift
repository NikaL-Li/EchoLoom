import SwiftUI

struct YZPressableButtonStyle: ButtonStyle {
    @Environment(\.yzTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? theme.motion.pressScale : 1)
            .brightness(configuration.isPressed && theme.motion.reduceMotion ? 0.08 : 0)
            .animation(theme.motion.pressAnimation, value: configuration.isPressed)
    }
}

private struct YZCardPressModifier: ViewModifier {
    @Environment(\.yzTheme) private var theme
    @State private var isPressing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressing ? theme.motion.pressScale : 1)
            .brightness(isPressing && theme.motion.reduceMotion ? 0.08 : 0)
            .animation(theme.motion.pressAnimation, value: isPressing)
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressing = pressing
                },
                perform: {}
            )
    }
}

private struct YZCardEntranceModifier: ViewModifier {
    let isVisible: Bool
    @Environment(\.yzTheme) private var theme

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : theme.motion.cardEntranceOffset)
            .animation(theme.motion.cardEntranceAnimation, value: isVisible)
    }
}

extension View {
    func yzCardPress() -> some View {
        modifier(YZCardPressModifier())
    }

    func yzCardEntrance(isVisible: Bool) -> some View {
        modifier(YZCardEntranceModifier(isVisible: isVisible))
    }
}