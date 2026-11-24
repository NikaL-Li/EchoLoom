import SwiftUI

struct YZShadowTokens {
    struct Entry {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let none = Entry(color: .clear, radius: 0, x: 0, y: 0)
    }

    let card: Entry
    let secondaryButton: Entry
    let segmentThumb: Entry
    let toast: Entry
    let talkBar: Entry
    let dockUp: Entry
    let closePill: Entry
    let dockPrimary: Entry
    let banner: Entry
    let sheetUp: Entry

    static func resolve(_ colors: YZColorTokens) -> YZShadowTokens {
        let card = Entry(color: colors.shadowColor, radius: 12, x: 0, y: 2)
        if colors.isDark {
            return YZShadowTokens(
                card: .none,
                secondaryButton: .none,
                segmentThumb: .none,
                toast: .none,
                talkBar: .none,
                dockUp: Entry(color: Color(yzHex: 0x000000, opacity: 0.24), radius: 30, x: 0, y: -10),
                closePill: .none,
                dockPrimary: .none,
                banner: .none,
                sheetUp: Entry(color: Color(yzHex: 0x000000, opacity: 0.35), radius: 30, x: 0, y: -10)
            )
        }
        return YZShadowTokens(
            card: card,
            secondaryButton: Entry(color: colors.shadowColor, radius: 8, x: 0, y: 2),
            segmentThumb: Entry(color: colors.shadowColor, radius: 4, x: 0, y: 1),
            toast: Entry(color: Color(yzHex: 0x0F1A2E, opacity: 0.10), radius: 20, x: 0, y: 6),
            talkBar: card,
            dockUp: card,
            closePill: card,
            dockPrimary: card,
            banner: card,
            sheetUp: Entry(color: Color(yzHex: 0x1E3C78, opacity: 0.18), radius: 40, x: 0, y: -12)
        )
    }
}

extension View {
    func yzShadow(_ entry: YZShadowTokens.Entry) -> some View {
        shadow(color: entry.color, radius: entry.radius, x: entry.x, y: entry.y)
    }
}