import SwiftUI

public struct SceneNavBar: View {
    public let scenes: [SceneKind]
    public let selectedScene: SceneKind
    public let subs: [String]
    public let selectedSub: String
    public let navStyle: SceneNavStyle
    public let onSelectScene: (SceneKind) -> Void
    public let onSelectSub: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    public init(
        scenes: [SceneKind] = SceneKind.allCases,
        selectedScene: SceneKind,
        subs: [String],
        selectedSub: String,
        navStyle: SceneNavStyle,
        onSelectScene: @escaping (SceneKind) -> Void,
        onSelectSub: @escaping (String) -> Void
    ) {
        self.scenes = scenes
        self.selectedScene = selectedScene
        self.subs = subs
        self.selectedSub = selectedSub
        self.navStyle = navStyle
        self.onSelectScene = onSelectScene
        self.onSelectSub = onSelectSub
    }

    public init(
        selectedScene: SceneKind,
        selectedSub: String,
        onSelectScene: @escaping (SceneKind) -> Void,
        onSelectSub: @escaping (String) -> Void
    ) {
        let pack = SceneCatalog.pack(for: selectedScene)
        self.init(
            scenes: SceneKind.allCases,
            selectedScene: selectedScene,
            subs: pack.subs,
            selectedSub: selectedSub,
            navStyle: pack.navStyle,
            onSelectScene: onSelectScene,
            onSelectSub: onSelectSub
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sceneChips

            if !subs.isEmpty {
                if navStyle == .step {
                    stepBar
                } else {
                    SceneUnderlineTabs(items: subs, selected: selectedSub, onSelect: onSelectSub)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var sceneChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scenes) { scene in
                    let isSelected = scene == selectedScene
                    Button {
                        onSelectScene(scene)
                    } label: {
                        Text(scene.title)
                            .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color.white : SceneTheme.chipInk(scheme))
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background(
                                isSelected
                                    ? SceneTheme.primaryFill(scheme)
                                    : SceneTheme.chipBackground(scheme)
                            )
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(scene.title)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
        }
    }

    private var stepBar: some View {
        let current = subs.firstIndex(of: selectedSub) ?? 0

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(subs.indices), id: \.self) { index in
                    stepItem(index: index, name: subs[index], current: current)
                        .frame(width: 76)
                        .background(alignment: .topLeading) {
                            if index > 0 {
                                Rectangle()
                                    .fill(
                                        index < current
                                            ? SceneTheme.stepDoneLine(scheme)
                                            : SceneTheme.line(scheme)
                                    )
                                    .frame(width: 76, height: 2)
                                    .offset(x: -38, y: 10)
                            }
                        }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private func stepItem(index: Int, name: String, current: Int) -> some View {
        let isDone = index < current
        let isCurrent = index == current

        return Button {
            onSelectSub(name)
        } label: {
            VStack(spacing: 6) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(dotForeground(isDone: isDone, isCurrent: isCurrent))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(dotBackground(isDone: isDone, isCurrent: isCurrent))
                    )
                    .overlay {
                        if isCurrent {
                            Circle()
                                .stroke(SceneTheme.soft(scheme), lineWidth: 4)
                                .padding(-4)
                        }
                    }

                Text(name)
                    .font(.system(size: 13, weight: isCurrent ? .semibold : .medium))
                    .foregroundStyle(
                        isDone || isCurrent
                            ? SceneTheme.primary(scheme)
                            : SceneTheme.ink3(scheme)
                    )
                    .fixedSize()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func dotForeground(isDone: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return .white }
        if isDone { return SceneTheme.primary(scheme) }
        return SceneTheme.ink3(scheme)
    }

    private func dotBackground(isDone: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return SceneTheme.primaryFill(scheme) }
        if isDone { return SceneTheme.soft(scheme) }
        return SceneTheme.stepDotBackground(scheme)
    }
}

struct SceneUnderlineTabs: View {
    let items: [String]
    let selected: String
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(items, id: \.self) { name in
                    let isSelected = name == selected
                    Button {
                        onSelect(name)
                    } label: {
                        VStack(spacing: 0) {
                            Text(name)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(
                                    isSelected
                                        ? SceneTheme.primary(scheme)
                                        : SceneTheme.chipInk(scheme)
                                )
                                .padding(.vertical, 10)
                                .fixedSize()

                            Rectangle()
                                .fill(isSelected ? SceneTheme.primary(scheme) : Color.clear)
                                .frame(height: 2)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(name)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .background(alignment: .bottom) {
            Rectangle()
                .fill(SceneTheme.line(scheme))
                .frame(height: 1)
                .padding(.horizontal, -2)
        }
    }
}