import SwiftUI
import Foundation

private func previewDate(hour: Int, minute: Int) -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 1
    components.day = 1
    components.hour = hour
    components.minute = minute
    return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
}

private enum PreviewSamples {
    static let threeStates: [YZMessage] = [
        YZMessage(
            id: "preview.other.1",
            direction: .other,
            text: "请问您哪里不舒服？",
            statusText: "已识别",
            createdAt: previewDate(hour: 14, minute: 32)
        ),
        YZMessage(
            id: "preview.mine.plain",
            direction: .mine,
            text: "我听力不好，请说慢一点。",
            statusText: "文字直达",
            createdAt: previewDate(hour: 14, minute: 33)
        ),
        YZMessage(
            id: "preview.mine.ok",
            direction: .mine,
            text: "这个药一天吃两次。",
            statusText: "已播报",
            createdAt: previewDate(hour: 14, minute: 34)
        ),
        YZMessage(
            id: "preview.mine.fail",
            direction: .mine,
            text: "请帮我预约下周复查。",
            statusText: "播报失败",
            createdAt: previewDate(hour: 14, minute: 35)
        )
    ]

    static let time1432: [YZMessage] = [
        YZMessage(
            id: "preview.other.1432",
            direction: .other,
            text: "今天感觉怎么样？",
            statusText: "已识别",
            createdAt: previewDate(hour: 14, minute: 32)
        )
    ]

    static let longText: [YZMessage] = [
        YZMessage(
            id: "preview.mine.long",
            direction: .mine,
            text: "我需要向医生说明：我听不见，请尽量看着我说慢一点，如果我没听清会用文字回复你，也请把关键信息写下来，谢谢。",
            statusText: "文字直达",
            createdAt: previewDate(hour: 14, minute: 40)
        )
    ]

    static let pair: [YZMessage] = [
        YZMessage(
            id: "preview.other.pair",
            direction: .other,
            text: "请问需要我写下来吗？",
            statusText: "已识别",
            createdAt: previewDate(hour: 14, minute: 30)
        ),
        YZMessage(
            id: "preview.mine.pair",
            direction: .mine,
            text: "需要，谢谢。",
            statusText: "文字直达",
            createdAt: previewDate(hour: 14, minute: 31)
        )
    ]
}

private struct DialogPreviewHost: View {
    let baseline: YZBaseline
    let phraseBaseline: YZPhraseBaseline
    let scheme: ColorScheme
    let sceneID: String?
    let phaseID: String?
    let selectedView: YZDialogView
    let width: CGFloat
    let height: CGFloat
    let typeSize: DynamicTypeSize
    let reduceMotion: Bool
    let composerPresented: Bool
    let composerDraft: String

    @State private var appState: YZAppState
    @State private var dependencies: DialogDependencies

    @MainActor
    init(
        baseline: YZBaseline = .threeMessages,
        phraseBaseline: YZPhraseBaseline = .six,
        messages: [YZMessage]? = nil,
        scheme: ColorScheme,
        sceneID: String? = nil,
        phaseID: String? = nil,
        selectedView: YZDialogView = .dialog,
        width: CGFloat = 430,
        height: CGFloat = 932,
        typeSize: DynamicTypeSize = .large,
        reduceMotion: Bool = false,
        composerPresented: Bool = false,
        composerDraft: String = ""
    ) {
        self.baseline = baseline
        self.phraseBaseline = phraseBaseline
        self.scheme = scheme
        self.sceneID = sceneID
        self.phaseID = phaseID
        self.selectedView = selectedView
        self.width = width
        self.height = height
        self.typeSize = typeSize
        self.reduceMotion = reduceMotion
        self.composerPresented = composerPresented
        self.composerDraft = composerDraft

        let toastCenter = ToastCenter()
        _dependencies = State(initialValue: DialogDependencies.placeholder(baseline: baseline, toastCenter: toastCenter))

        let baseSession = YZMockData.session(baseline: baseline, phraseBaseline: phraseBaseline)
        let session = YZDialogSession(
            scenes: baseSession.scenes,
            phases: baseSession.phases,
            messages: messages ?? baseSession.messages,
            phrases: baseSession.phrases
        )
        let state = YZAppState(session: session, phraseBaseline: phraseBaseline)
        if let selectedScene = sceneID {
            state.selectScene(selectedScene)
        }
        if let selectedPhase = phaseID {
            state.selectPhase(selectedPhase)
        }
        if selectedView != .dialog {
            state.selectView(selectedView)
        }
        _appState = State(initialValue: state)
    }

    var body: some View {
        let theme = dependencies.themeProvider.theme(for: scheme, reduceMotion: reduceMotion)

        StaticDialogPage(
            dependencies: dependencies,
            sceneNav: { SceneNavBar(context: $0) },
            phraseContent: { SayList(context: $0) },
            composerInitiallyPresented: composerPresented,
            composerInitialDraft: composerDraft
        )
        .environment(\.yzTheme, theme)
        .environment(appState)
        .preferredColorScheme(scheme)
        .dynamicTypeSize(typeSize)
        .environment(\.accessibilityReduceMotion, reduceMotion)
        .frame(width: width, height: height)
    }
}

#Preview("P1 浅色 3条 就医·问诊") {
    DialogPreviewHost(scheme: .light)
}

#Preview("P2 深色 3条 就医·问诊") {
    DialogPreviewHost(scheme: .dark)
}

#Preview("P3 浅色 0条 就医·挂号") {
    DialogPreviewHost(baseline: .empty, scheme: .light, phaseID: "medical.register")
}

#Preview("P4 浅色 紧急·求助") {
    DialogPreviewHost(scheme: .light, sceneID: "emergency", phaseID: "emergency.help")
}

#Preview("P5 深色 紧急·求助") {
    DialogPreviewHost(scheme: .dark, sceneID: "emergency", phaseID: "emergency.help")
}

#Preview("P6 320 AX3 减少动态 紧急") {
    DialogPreviewHost(
        scheme: .light,
        sceneID: "emergency",
        phaseID: "emergency.help",
        width: 320,
        height: 568,
        typeSize: .accessibility3,
        reduceMotion: true
    )
}

#Preview("P7 深色 点餐·点单 440") {
    DialogPreviewHost(scheme: .dark, sceneID: "meal", phaseID: "meal.order", width: 440, height: 956)
}

#Preview("P8 浅色 iPad 横屏") {
    DialogPreviewHost(scheme: .light, width: 1024, height: 768)
}

#Preview("P9 浅色 减少动态") {
    DialogPreviewHost(scheme: .light, reduceMotion: true)
}

#Preview("P10 浅色 问诊 6 句") {
    DialogPreviewHost(scheme: .light, selectedView: .phrases)
}

#Preview("P11 浅色 句表空态") {
    DialogPreviewHost(phraseBaseline: .empty, scheme: .light, selectedView: .phrases)
}

#Preview("P12 深色 句表") {
    DialogPreviewHost(scheme: .dark, selectedView: .phrases)
}

#Preview("P13 浅色 我方三态 + 对方") {
    DialogPreviewHost(messages: PreviewSamples.threeStates, scheme: .light, width: 430, height: 1100)
}

#Preview("P14 浅色 医生 · 14:32") {
    DialogPreviewHost(messages: PreviewSamples.time1432, scheme: .light)
}

#Preview("P15 浅色 240pt 长句") {
    DialogPreviewHost(messages: PreviewSamples.longText, scheme: .light, width: 240, height: 800)
}

#Preview("P16 320 AX3 我方卡片") {
    DialogPreviewHost(
        messages: [PreviewSamples.pair[1]],
        scheme: .light,
        width: 320,
        height: 568,
        typeSize: .accessibility3
    )
}

#Preview("P17 深色 双方卡片") {
    DialogPreviewHost(messages: PreviewSamples.pair, scheme: .dark, width: 430, height: 720)
}
#Preview("P18 浅色 抽屉打开") {
    DialogPreviewHost(scheme: .light, composerPresented: true)
}

#Preview("P19 浅色 抽屉输入中") {
    DialogPreviewHost(
        scheme: .light,
        composerPresented: true,
        composerDraft: "请把刚才的话写下来，谢谢。"
    )
}

#Preview("P20 浅色 发送后抽屉不关") {
    DialogPreviewHost(
        messages: PreviewSamples.pair,
        scheme: .light,
        composerPresented: true
    )
}

#Preview("P21 320 AX3 抽屉") {
    DialogPreviewHost(
        scheme: .light,
        width: 320,
        height: 568,
        typeSize: .accessibility3,
        composerPresented: true
    )
}

#Preview("P22 深色 抽屉打开") {
    DialogPreviewHost(scheme: .dark, composerPresented: true)
}