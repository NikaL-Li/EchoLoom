# FeatureScenes（P2 · 场景与常用语）

「译诊」iOS 17 / SwiftUI 的独立功能包，数据照 `index(4).html` 的 `SCENES` 原样搬入。

## 目录

```
FeatureScenes/
├── Package.swift
├── Sources/FeatureScenes/
│   ├── SceneCatalog.swift           五个场景、环节、内置句子、术语、默认环节
│   ├── SceneTheme.swift             本模块自带浅色/深色配色（不依赖主题文件）
│   ├── SceneNavBar.swift            场景胶囊 + 就医步骤条 / 其他下划线标签
│   ├── SayList.swift                可播句列表、已播状态与计数
│   ├── PhrasesView.swift            我的常用语、添加/编辑/删除
│   ├── TermHint.swift               术语匹配与提示条
│   ├── YZPhraseStoring.swift        自定义句子协议 + UserDefaults 实现
│   └── SceneSwitchCoordinator.swift 切场景 / 切环节行为（P2-7）
└── Tests/FeatureScenesTests/
    ├── SceneCatalogTests.swift
    ├── PhraseStoreTests.swift
    ├── TermMatcherTests.swift
    └── SceneSwitchTests.swift
```

核心交付文件：`SceneCatalog.swift`、`SceneNavBar.swift`、`SayList.swift`、`PhrasesView.swift`、`TermHint.swift`、`YZPhraseStoring.swift`。

内部依赖（必须一起复制，否则无法编译）：`SceneTheme.swift`。`SceneSwitchCoordinator.swift` 是 P2-7 的切换行为，建议一并带上，P3 可直接复用。

## 合并入口（P1）

1. 对话页顶部：放 `SceneNavBar`，接 `onSelectScene` / `onSelectSub`。
2. 对话页「常用语」分页：放 `SayList`，接 `onSelect`。
3. 「我的」页：加一个入口，push / sheet 打开 `PhrasesView`。
4. 输入框或对方字幕区上方：放 `TermHint`。

以上四个组件都不自己持有场景状态，全部从外部传入并回调。

## P3 需要传的参数

`SceneNavBar`：

```swift
SceneNavBar(
    selectedScene: scene,
    selectedSub: sub,
    onSelectScene: { newScene in /* 走 YZSceneSwitching.switchScene */ },
    onSelectSub: { newSub in /* 走 YZSceneSwitching.switchSub */ }
)
```

需要保留 `scenes` / `subs` / `navStyle` 自定义时，使用完整初始化：

```swift
SceneNavBar(
    scenes: SceneKind.allCases,
    selectedScene: scene,
    subs: SceneCatalog.subs(for: scene),
    selectedSub: sub,
    navStyle: SceneCatalog.pack(for: scene).navStyle,
    onSelectScene: { _ in },
    onSelectSub: { _ in }
)
```

`SayList`：

```swift
SayList(
    items: SceneCatalog.phrases(for: scene, sub: sub),
    subSceneName: sub,
    playCounts: $playCounts,     // [String: Int]，key 用句子原文
    onSelect: { text in /* P3 播报并写入对话流 */ }
)
```

`TermHint`：

```swift
let term = TermMatcher.match(userText, in: SceneCatalog.terms(for: scene))
TermHint(term: term, scene: scene)
```

`PhrasesView`：

```swift
PhrasesView(
    scene: scene,
    initialSub: sub,
    store: phraseStore,
    onBack: { /* 返回我的 */ },
    onSend: { text in /* 发到对话流并返回对话页 */ }
)
```

## P2-7 切换行为

`YZSceneSwitching` 是纯状态机，P3 的对话 ViewModel 持有即可：

```swift
var switcher = YZSceneSwitching(scene: .medical)

let outcome = switcher.switchScene(
    to: newScene,
    turns: currentTurns,                 // 当前这一轮已经说过的话
    store: sessionStore                  // P4 实现；没有就传 YZNoopSessionStore()
)
// outcome.savedSession 表示是否存成一次会话
// outcome.dividerText 是「— 就医 · 问诊 新会话 —」
// P3 在此处清空当前对话、写入 divider

switcher.switchSub(to: newSub)           // 不清空对话，只换句子/术语，并清掉 divider
```

`switchScene` 在会话保存失败时不会中断切换，失败信息放在 `outcome.saveError`，由 P3 决定是否提示。

## 数据存在哪里

- 自定义句子：`UserDefaults`，key 为 `yizhen.myPhrases.v1`。
- 存储格式：`{"场景|环节": ["句子", ...]}`，例如 `{"就医|问诊": ["请写下来给我看。"]}`。
- 分组键：`YZUserDefaultsPhraseStore.groupKey(scene:sub:)`，格式固定为 `场景|环节`。
- 已播次数：由 P3 持有 `[String: Int]`；`SayList` 点击时会递增该 binding，key 为句子原文。本模块不负责持久化，切换场景时请按场景重置或隔离该字典。
- 会话：交给 P4 的 `YZSessionStoring`；默认 `YZNoopSessionStore` 不写入、不报错。

## 需要别人配合的地方

- P1：在对话页顶部、常用语分页、「我的」页、输入区分别接入上述四个入口；不要修改本模块内部文件。
- P3：维护 `selectedScene` / `selectedSub` / `turns` / `playCounts`，点击句子后负责播报和写入对话流；切场景时按 `YZSceneSwitching` 的返回值清空对话并写入分隔条。
- P4：实现 `YZSessionStoring` 以真正落盘会话；未就绪时用 `YZNoopSessionStore`。
- 主题：本模块自带 `SceneTheme`，未引用主题文件；若要与全局主题统一，只替换 `SceneTheme` 内部颜色即可。
- 语音：`SayList` 只回传文字，不接 TTS；播报由 P3 负责。

## 验证说明

数据层已与 `index(4).html` 的 `SCENES` 逐条比对：5 个场景、环节数量、每环节 6 句、就医 70 条术语、其余各 10 条、术语 id 全局唯一。

本环境没有 Swift / Xcode 工具链，测试未实际执行；请在 Xcode 中打开 `FeatureScenes/Package.swift` 运行 `SceneCatalogTests`、`PhraseStoreTests`、`TermMatcherTests`、`SceneSwitchTests`。