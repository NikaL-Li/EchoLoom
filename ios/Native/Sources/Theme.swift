import SwiftUI
import UIKit

private func adaptive(dark: UInt32, light: UInt32) -> Color {
    Color(uiColor: UIColor { trait in
        let hex = trait.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    })
}
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: alpha)
    }
    static let ylctCanvas = adaptive(dark: 0x0B1220, light: 0xF3F6FB)
    static let ylctCanvasLift = adaptive(dark: 0x101B2D, light: 0xEAF0F8)
    static let ylctText = adaptive(dark: 0xF1F5FC, light: 0x15233B)
    static let ylctTextSecondary = adaptive(dark: 0xAAB8CD, light: 0x596A82)
    static let ylctBlue = adaptive(dark: 0x94BBFF, light: 0x2459C6)
    static let ylctCyan = ylctBlue
    static let ylctMint = adaptive(dark: 0x7EDBC8, light: 0x08796B)
    static let ylctOrange = adaptive(dark: 0xF0C383, light: 0x946015)
    static let ylctGold = ylctOrange
    static let ylctSun = Color(hex: 0xFFD187)
    static let ylctAction = Color(hex: 0x285BCD)
    static let ylctTealAction = Color(hex: 0x08786D)
    static let ylctDanger = adaptive(dark: 0xFFA49F, light: 0xBA3438)
    static let ylctNavy = Color(hex: 0x0B1220)
    static let ylctInk = Color(hex: 0x101A2C)
    static let ylctHeroTop = Color(hex: 0x24496D)
    static let ylctHeroBottom = Color(hex: 0x0B1E36)
    static let ylctSurface = adaptive(dark: 0x152136, light: 0xFFFFFF)
    static let ylctSurfaceSoft = adaptive(dark: 0x1C2B43, light: 0xEDF2F9)
    static let ylctField = adaptive(dark: 0x101B2D, light: 0xF7F9FD)
    static let ylctStroke = adaptive(dark: 0x2B3A51, light: 0xDDE5F0)
}
// The canvas supplies a quiet, stationary color field for the optical surfaces.
struct YLCTBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var solid
    var body: some View {
        ZStack {
            Color.ylctCanvas
            if !solid {
                LinearGradient(colors: [.ylctBlue.opacity(0.17), .clear, .ylctMint.opacity(0.13)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                EllipticalGradient(colors: [.ylctMint.opacity(0.18), .clear], center: .topTrailing,
                                   startRadiusFraction: 0, endRadiusFraction: 0.86)
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct OpticalSurface<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let solidFill: Color
    let responds: Bool
    @Environment(\.accessibilityReduceTransparency) private var solid
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var still
    @Environment(\.isEnabled) private var enabled
    @ViewBuilder func body(content: Content) -> some View {
        if solid || contrast == .increased {
            content.background(solidFill, in: shape)
                .overlay { shape.stroke(Color.ylctTextSecondary.opacity(0.44), lineWidth: 1).allowsHitTesting(false) }
        } else if #available(iOS 26, *) {
            let surface = tint.map { Glass.regular.tint($0) } ?? .regular
            content.glassEffect(responds && enabled && !still ? surface.interactive() : surface, in: shape)
        } else {
            content.background {
                if tint != nil { shape.fill(solidFill) }
                else { shape.fill(.regularMaterial) }
            }
                .overlay { shape.stroke(Color.ylctStroke, lineWidth: 0.75).allowsHitTesting(false) }
        }
    }
}

// A single continuous reading surface for native grouped rows; separators, swipe
// actions, pickers and text selection remain native.
struct YLCTReadingPlate: View {
    @Environment(\.accessibilityReduceTransparency) private var solid
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        Color.ylctSurface.opacity(solid || contrast == .increased ? 1 : 0.73)
    }
}

private struct OpticalGroup: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var solid
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *), !solid, contrast != .increased {
            // Smaller than the gutter so adjacent actions never visually fuse.
            GlassEffectContainer(spacing: 2) { content }
        } else { content }
    }
}

extension View {
    @ViewBuilder func ylctGlass<S: Shape>(_ shape: S, tint: Color? = nil, solid: Color = .ylctSurface, touch: Bool = false) -> some View {
        let surface = OpticalSurface(shape: shape, tint: tint, solidFill: solid, responds: touch)
        if touch { self.contentShape(shape).modifier(surface).contentShape(shape) }
        else { modifier(surface) }
    }
    func ylctLens(_ radius: CGFloat, tint: Color? = nil, solid: Color = .ylctSurface, touch: Bool = false) -> some View {
        ylctGlass(RoundedRectangle(cornerRadius: radius, style: .continuous), tint: tint, solid: solid, touch: touch)
    }
    func ylctGroup() -> some View { modifier(OpticalGroup()) }
    func ylctCard(radius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        self.padding(padding).ylctLens(radius)
    }
    func ylctPill() -> some View { padding(.horizontal, 14).padding(.vertical, 8).ylctGlass(Capsule()) }
    func ylctListCanvas() -> some View { scrollContentBackground(.hidden).background(YLCTBackground()) }
    // A steady backing for the text field, transport controls and progress clock.
    // Individual buttons above it provide the optical layer.
    func ylctDock() -> some View {
        background(Color.ylctCanvasLift).overlay(alignment: .top) { Divider().allowsHitTesting(false) }
    }
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
struct GlassIconButton: View {
    let systemName: String
    var label = "关闭"
    var tint: Color = .ylctText
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName).font(.body.weight(.semibold)).foregroundStyle(tint)
                .frame(width: 44, height: 44).ylctGlass(Circle(), touch: true)
        }.buttonStyle(PressStyle()).accessibilityLabel(label)
    }
}
struct StatusDot: View {
    let active: Bool
    var body: some View { Circle().fill(active ? Color.ylctMint : Color.ylctTextSecondary).frame(width: 7, height: 7).accessibilityHidden(true) }
}
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) { if let systemImage { Image(systemName: systemImage) }; Text(title) }
                .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 52)
                .ylctLens(17, tint: .ylctAction, solid: .ylctAction, touch: true).opacity(enabled ? 1 : 0.45)
        }.buttonStyle(PressStyle())
    }
}
struct FieldLabel: View {
    let text: String
    var body: some View { Text(text).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctTextSecondary).frame(maxWidth: .infinity, alignment: .leading) }
}

private struct PlaybackClockKey: EnvironmentKey {
    static let defaultValue: PlaybackProgressClock? = nil
}
extension EnvironmentValues {
    var playbackClock: PlaybackProgressClock? {
        get { self[PlaybackClockKey.self] }
        set { self[PlaybackClockKey.self] = newValue }
    }
}

// Timeline invalidation stays inside the visible playback leaf. Completed history
// has no running timeline, and sampling never redraws the surrounding conversation.
struct PlaybackTimeline<Content: View>: View {
    let snapshot: PlaybackSnapshot
    var minimumInterval: TimeInterval = 1.0 / 60.0
    @ViewBuilder var content: (PlaybackSnapshot) -> Content
    @Environment(\.playbackClock) private var clock
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if snapshot.phase == .playing {
            TimelineView(.animation(minimumInterval: reduceMotion ? max(0.1, minimumInterval) : minimumInterval, paused: scenePhase != .active)) { _ in
                content(clock?.sample(fallback: snapshot) ?? snapshot)
            }
        } else {
            content(snapshot)
        }
    }
}

struct PlaybackProgressView: View {
    let snapshot: PlaybackSnapshot
    var showsTrack = true
    var identifier = "playback.progress"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var tint: Color {
        snapshot.phase == .completed ? .ylctMint : snapshot.phase == .failed ? .ylctDanger : .ylctBlue
    }
    var body: some View {
        PlaybackTimeline(snapshot: snapshot) { live in
            progressContent(live)
        }.id(snapshot.id)
    }
    private func progressContent(_ live: PlaybackSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if snapshot.phase == .preparing { ProgressView().controlSize(.mini) }
                else {
                    Image(systemName: snapshot.phase == .completed ? "checkmark.circle.fill" : snapshot.phase == .stopped ? "stop.circle" : snapshot.phase == .failed ? "exclamationmark.circle" : "speaker.wave.2.fill")
                }
                Text(snapshot.phase.label).fontWeight(.semibold)
                Spacer(minLength: 6)
                Text(live.timingLabel).monospacedDigit()
            }.font(.caption).foregroundStyle(tint)
            if showsTrack {
                if live.phase == .playing, live.duration == nil {
                    // Direct system speech has no total duration. Show continuous
                    // activity instead of a word-driven, misleading audio percent.
                    GeometryReader { geometry in
                        Capsule().fill(tint.opacity(0.15))
                        Capsule().fill(tint.opacity(reduceMotion ? 0.5 : 1))
                            .frame(width: geometry.size.width * 0.3)
                            .offset(x: reduceMotion ? geometry.size.width * 0.35 : geometry.size.width * 0.7 * (0.5 - 0.5 * cos(live.elapsed * .pi)))
                    }.frame(height: 4).accessibilityHidden(true)
                } else {
                    ProgressView(value: live.progress).tint(tint).accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("播放进度")
        .accessibilityValue(live.accessibilityValue)
        .accessibilityIdentifier(identifier)
    }
}

private struct PlaybackFillModifier: ViewModifier {
    let snapshot: PlaybackSnapshot?
    var radius: CGFloat
    var tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content
            .background(alignment: .leading) {
                if let snapshot {
                    PlaybackTimeline(snapshot: snapshot) { live in
                        GeometryReader { geometry in
                            if live.phase == .playing, live.duration == nil {
                                tint.opacity(0.13).frame(width: geometry.size.width * 0.4)
                                    .offset(x: reduceMotion ? geometry.size.width * 0.3 : geometry.size.width * 0.6 * (0.5 - 0.5 * cos(live.elapsed * .pi)))
                            } else {
                                tint.opacity(0.13).frame(width: geometry.size.width * live.progress)
                            }
                        }
                    }.id(snapshot.id).clipShape(RoundedRectangle(cornerRadius: radius)).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
    }
}
private struct PlaybackAccessibilityModifier: ViewModifier {
    let snapshot: PlaybackSnapshot?
    func body(content: Content) -> some View {
        if let snapshot {
            PlaybackTimeline(snapshot: snapshot, minimumInterval: 1) { live in
                content.accessibilityValue(live.accessibilityValue)
            }
        } else {
            content.accessibilityValue("尚未播报")
        }
    }
}
extension View {
    func playbackFill(_ snapshot: PlaybackSnapshot?, radius: CGFloat = 16, tint: Color = .ylctBlue) -> some View {
        modifier(PlaybackFillModifier(snapshot: snapshot, radius: radius, tint: tint))
    }
    func playbackAccessibilityValue(_ snapshot: PlaybackSnapshot?) -> some View {
        modifier(PlaybackAccessibilityModifier(snapshot: snapshot))
    }
}
