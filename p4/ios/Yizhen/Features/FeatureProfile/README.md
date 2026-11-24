# FeatureProfile 交接包

「我的」页与「使用指南 + 权限」页。文件直接并入 P1 的 App target（`ios/Yizhen/Features/FeatureProfile/`），使用 P1 `Shared` 中的内部类型。

## 交付内容

- `ProfileView`：「我的」Tab 内容；用户卡、常用语/指南入口、外观三段、设置卡、版本脚注。P1 `RootView` 实际是「首页 / 记录 / 我的」三 Tab，本包不建 Tab。
- `GuideView`：使用指南五步 + 麦克风/语音识别权限；只读查询，不申请。
- 与 P1 的关系：外观/字号/高对比/全程文字是 `Binding`，状态归 P1 `YZAppState`；本包提供 `YZProfileSettingsPersistence` 写 UserDefaults，不另建状态副本。

## 文件清单

```text
FeatureProfile/
├── ProfileView.swift
├── GuideView.swift
├── Internal/
│   ├── YZProfileSupport.swift
│   ├── YZProfileComponents.swift
│   ├── YZGuideSupport.swift
│   ├── YZGuideComponents.swift
│   ├── YZGuideSystemPermissionQuery.swift
│   └── YZProfileSettingsPersistence.swift
├── Preview/
│   ├── YZProfilePreviewProvider.swift
│   └── YZGuidePreviewProvider.swift
└── README.md
```

## P1 实际 API 对齐

- 外观：`YZThemeMode.system / .light / .dark`，用 P1 `YZSegmented` 展示。
- 字号：`YZFontSize.normal(18) / .large(24) / .xlarge(30)`，用 P1 `YZPillButton` 展示。
- 高对比/全程文字：`Bool` Binding，对应 `YZAppState.highContrast` / `textOnly`。
- 视觉：全部用 `YZTheme`、`YZCard`、`YZListRow`、`YZSwitchRow`、`YZSegmented`、`YZPillButton`。
- 类型保持 module internal，与 P1 一致。

## 合并

1. 复制整个 `FeatureProfile/` 到 `ios/Yizhen/Features/FeatureProfile/`。
2. `.profile` Tab 使用 `@Bindable` 生成 Binding：
```swift
@Bindable var appState = appState
ProfileView(
    appearance: $appState.themeMode,
    fontSize: $appState.fontSize,
    isHighContrastEnabled: $appState.highContrast,
    isTextOnlyMode: $appState.textOnly,
    phraseCountText: "\(appState.phraseCount) 条",
    versionText: versionText,
    onPhrasesTap: { appState.openPhrases() },
    onGuideTap: { appState.openGuide() }
)
```
3. `.guide` 路由使用 `GuideView { appState.closeRoute() }`；直接渲染，不再套 P1 的 `RoutePageView` 占位外壳，`GuideView` 自带「返回」。
4. `versionText` 由合并方读 `CFBundleShortVersionString` + `CFBundleVersion`。
5. 权限用途说明写入 P1 `project.yml` 或 Info.plist：
   `INFOPLIST_KEY_NSMicrophoneUsageDescription`、
   `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription`。

## 已完成 / 尚未闭环

- **设置持久化**：`YZProfileSettingsPersistence` 已把四项写入 UserDefaults；App 启动时 `YizhenApp` 调 `load(into:)`。键名：`yz.appearance.mode`、`yz.typography.fontSize`、`yz.display.highContrast`、`yz.voice.textOnly`。
- **外观全局生效**：P1 `RootView` 已按 `themeMode` 注入 `.preferredColorScheme`；跟随系统时传 `nil`。
- **字号全局生效**：`YZThemeRuntime` + P1 Theme 计算字体，18/24/30 三档作用于现有页面；标题/按钮/行高按档位受限增长，窄屏用 `ViewThatFits` 兜底。
- **高对比**：Theme 切到白底黑字黑边，组件与自定义卡片补 2pt 黑边、阴影清零；强制浅色；首页大图在对比模式下替换为白底文字卡。
- **全程文字**：P3 尚无 `stopListening()` / 「文字直达」状态；本包只持久化开关与说明。
- **权限**：查询已实现；`project.yml` 已补两条用途说明；真机弹窗仍需验收。
- **P3 要点**：仍固定「暂不可用」。
- **当前 Windows 无法构建**：以上结论均为源码与静态核对，需 macOS + Xcode 16 真实验证。

## 边界

- **两个 Feature 目录本身**只包含 Profile/Guide 页面与设置持久化，不改 P1 页面结构。
- 合并工程为完成字号/高对比/首页色，已额外修改 P1 的 `Theme`、`Components`、`HomeView`、`EmergencySignView`、`PlaceholderView`、`RootView`、`YizhenApp`、`project.yml`；以 `ios/` 工程为准。
- 不申请麦克风、不采集音频、不打开第三方 URL。
- 当前 Windows 无法编译；需在 macOS + Xcode 16 合并后验证。