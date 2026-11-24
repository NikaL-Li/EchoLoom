import SwiftUI

struct SceneNavBar: View {
    let scenes: [SceneKind]
    let selectedScene: SceneKind
    let subs: [String]
    let selectedSub: String
    let navStyle: SceneNavStyle
    let onSelectScene: (SceneKind) -> Void
    let onSelectSub: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    init(
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

    init(
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

    var body: some View {
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
                            .font(
                                YZTheme.font(
                                    size: 12.5,
                                    weight: isSelected ? .semibold : .medium,
                                    textStyle: .footnote,
                                    maxSize: 20
                                )
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(
                                isSelected ? SceneTheme.onPrimary : SceneTheme.chipInk(scheme)
                            )
                            .padding(.horizontal, 14)
                            .frame(minHeight: max(32, 32 * min(YZTheme.scale, 1.25)))
                            .background(
                                isSelected
                                    ? SceneTheme.chipSelectedBackground(scheme)
                                    : SceneTheme.chipBackground(scheme)
                            )
                            .clipShape(Capsule())
                            .overlay {
                                if YZTheme.highContrast {
                                    Capsule().stroke(Color.black, lineWidth: 1.5)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(YZPressButtonStyle())
                    .accessibilityLabel(scene.title)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
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
            .padding(.vertical, 8)
        }
        .scrollClipDisabled()
    }

    private func stepItem(index: Int, name: String, current: Int) -> some View {
        let isDone = index < current
        let isCurrent = index == current
        let dotSize = max(22, 22 * min(YZTheme.scale, 1.15))

        return Button {
            onSelectSub(name)
        } label: {
            VStack(spacing: 6) {
                Text("\(index + 1)")
                    .font(
                        YZTheme.font(
                            size: 12,
                            weight: .bold,
                            textStyle: .caption,
                            maxSize: 17
                        )
                    )
                    .foregroundStyle(dotForeground(isDone: isDone, isCurrent: isCurrent))
                    .frame(width: dotSize, height: dotSize)
                    .background(
                        Circle().fill(dotBackground(isDone: isDone, isCurrent: isCurrent))
                    )
                    .overlay {
                        if YZTheme.highContrast || isCurrent {
                            Circle()
                                .stroke(
                                    isCurrent && !YZTheme.highContrast
                                        ? SceneTheme.soft(scheme)
                                        : Color.black.opacity(YZTheme.highContrast ? 1 : 0),
                                    lineWidth: isCurrent && !YZTheme.highContrast ? 4 : 1.5
                                )
                                .padding(isCurrent && !YZTheme.highContrast ? -4 : 0)
                        }
                    }

                Text(name)
                    .font(
                        YZTheme.font(
                            size: 13,
                            weight: isCurrent ? .semibold : .medium,
                            textStyle: .footnote,
                            maxSize: 18
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(
                        isDone || isCurrent
                            ? SceneTheme.primary(scheme)
                            : SceneTheme.ink3(scheme)
                    )
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel(name)
        .accessibilityValue(isCurrent ? "当前环节" : (isDone ? "已完成" : "未开始"))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func dotForeground(isDone: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return YZTheme.highContrast ? .white : .white }
        if YZTheme.highContrast { return .black }
        if isDone { return SceneTheme.primary(scheme) }
        return SceneTheme.ink3(scheme)
    }

    private func dotBackground(isDone: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return YZTheme.highContrast ? .black : SceneTheme.primaryFill(scheme) }
        if YZTheme.highContrast { return .white }
        if isDone { return SceneTheme.soft(scheme) }
        return SceneTheme.stepDotBackground(scheme)
    }
}

struct SceneUnderlineTabs: View {
    let items: [String]
    let selected: String
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    init(items: [String], selected: String, onSelect: @escaping (String) -> Void) {
        self.items = items
        self.selected = selected
        self.onSelect = onSelect
    }

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
                                .font(
                                    YZTheme.font(
                                        size: 14,
                                        weight: isSelected ? .semibold : .medium,
                                        textStyle: .subheadline,
                                        maxSize: 20
                                    )
                                )
                                .lineLimit(1)
                                .foregroundStyle(
                                    isSelected
                                        ? SceneTheme.primary(scheme)
                                        : SceneTheme.chipInk(scheme)
                                )
                                .padding(.vertical, 10)

                            Rectangle()
                                .fill(isSelected ? SceneTheme.primary(scheme) : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(YZPressButtonStyle())
                    .accessibilityLabel(name)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
        .background(alignment: .bottom) {
            Rectangle()
                .fill(SceneTheme.line(scheme))
                .frame(height: 1)
        }
    }
}
