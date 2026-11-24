# 译诊 · P1 空壳与设计系统（SwiftUI）

iOS 17+ / SwiftUI / 无第三方依赖。

## 当前阶段

P1-7：页面切换与外壳细节。三 Tab 常驻保留滚动；对话页隐藏 Tab 并显示「关闭」；常用语/详情/指南保留 Tab 并显示「返回」；0.12 秒淡入与首页区块上浮。

## P1-1 已实现

- 底部悬浮胶囊导航（`.ultraThinMaterial`），高 64、左右距屏幕 14
- 「首页 / 记录 / 我的」三入口，选中浅蓝底 `#E8EDFB` + 深蓝 `#1B41C8`
- 页面背景 `#F2F4F8`，三个占位页

## P1-2 已实现

- `Shared/YZTheme.swift`：15 个颜色（Asset 颜色集，浅/深两套）、9 档字号、圆角/间距/尺寸、阴影
- `Shared/YZComponents.swift`：`YZCard`、`YZPrimaryButton`、`YZPillButton`、`YZListRow`、`YZSwitchRow`、`YZSegmented`、`YZToast`、`YZPageTitle`、`YZSectionTitle`
- `Preview/ComponentGallery.swift`：浅色块 + 深色块各排一遍
- `Assets.xcassets`：`YZBg … YZDangerSoft` 共 15 个 colorset

组件规格：

| 组件 | 规格 |
|---|---|
| YZCard | 圆角 24、内边距 16、阴影 `0 2 12 rgba(15,26,46,.05)` |
| YZPrimaryButton | 高 56、圆角 20、蓝底白字 17 Semibold |
| YZPillButton | 高 32 / 28（`.small`），可选中 |
| YZListRow | 行高 68、左侧 40 图标底 / 圆角 16 |
| YZSwitchRow | 行高 68、标题 + 说明 + Switch |
| YZSegmented | 三段等宽、选中白底 |
| YZToast | 黑底白字胶囊、底部弹出、1.8 秒消失（`.yzToast($text)`） |

## P1-3 已实现

- `Shared/YZModels.swift`：`YZScene`、`YZRole`、`YZTurn`、`YZSession`、`YZTerm`、`YZTab`、`YZRoute`
- `Shared/YZStores.swift`：`YZSessionStoring`、`YZPhraseStoring` + `YZMemorySessionStore` / `YZMemoryPhraseStore`
- `Shared/YZAppState.swift`：`@Observable` 全局状态，字段 `tab / route / scene / subScene / turns / sessions / themeMode / fontSize / highContrast / textOnly / faceToFace / toast`
- 方法：`selectTab` / `startTalk` / `closeTalk` / `openPhrases` / `openSession` / `openGuide` / `closeRoute` / `session(with:)`
- `YZTheme` 增加 `YZThemeMode`、`YZFontSize`（18/24/30）
- `YizhenApp` 注入 AppState；`RootView` 的 Tab 读写接到 `appState.tab`

数据规则：

- 正式启动 `sessions` 来自 `store.load()`（内存 store 初始为空），`turns` 为空
- `closeTalk` 时把非空 `turns` 封装成 `YZSession` 存入 store
- 假数据只在 `#if DEBUG` 的 `YZAppState.preview` 中，正式启动不预置任何会话

## P1-4 已实现

- `Views/HomeView.swift`：静态首页
- 问候 13 + 标题「译诊」34；今日对话卡 112 宽（绿勾、28 数字、「次」）
- 190 高大图卡：深蓝渐变 + 底部深色遮罩 + 26 号标语 + 右下四个圆点
- 区块标题「现在要做什么？」22 + 右侧「选好就开始」
- 两个 140 高入口：开始对话（深蓝）、一键亮牌（深绿），32 图标 / 20 标题 / 12 说明 / 右上箭头
- 列表卡两行：面对面模式、我的常用语（68 行、40 圆角图标底）
- 页面左右 16、区块 12、底部留 112

假数据：今日对话 0 次、常用语 6 条；入口点击暂不跳转。

## P1-5 已实现

- `Views/HeroCarousel.swift`：4 张轮播，替代首页内联大图
- `Assets.xcassets/hero1…hero4.imageset`：4 个图片位；当前无图时用不同色调渐变兜底
- 首帧显示第 1 张；每 4 秒自动切换；右下圆点可点直接切
- 交叉淡出 0.6 秒：新图先铺在下层，旧图在上层淡到透明，不露底色
- 图片 6 秒从 1 倍缓放到 1.06 倍，每次切图重置
- 图片缺失或加载失败时保留渐变与标语，不显示破图
- 系统「减少动态效果」开启时停止自动轮播与缩放

## P1-6 已实现

- 问候语：5–11 早上好 / 11–18 下午好 / 其余晚上好，后接「，今天也辛苦了」
- 首页「今日对话」读 `appState.todaySessionCount`（`endedAt` 是今天的会话数）
- 「我的常用语」读当前场景与环节的 `phraseCount`
- 四个入口：开始对话 → `startTalk()`；一键亮牌 → 紧急大字卡；面对面 → `startTalk(faceToFace: true)`；我的常用语 → `openPhrases()`
- `RootView` 按 `route` 显示占位页（对话 / 常用语 / 会话详情 / 指南），进入后隐藏底部 Tab
- `EmergencySignView`：红底白字 96 Heavy「我听不见，请帮我打 120。」，轻点关闭
- 假数据：`#if DEBUG` 的 `YZSampleData`（1 段今天的会话 + 就医·问诊 6 条常用语）；Release 启动为空

## P1-7 已实现

- 三 Tab 页面常驻 `ZStack`，切换只改 opacity，各自滚动位置保留
- 进入对话页：底部 Tab 隐藏，顶部左侧「关闭」胶囊（44 高），点击 `closeTalk()` 回首页
- 进入常用语：保留 Tab，顶部「返回」胶囊，点击 `closeRoute()`
- 会话详情 / 使用指南：直接渲染 Feature 页面，自带「返回」胶囊，保留 Tab
- Tab 与路由切换统一 0.12 秒 easeInOut 淡入，无其他转场
- 首页 4 个区块依次上浮 8 点，相邻延迟 40ms；减少动态效果时直接显示
- 底部 Tab 悬浮在安全区上方（`padding(.bottom, 10)`），内容底部留 112（对话页 82）
- 外观由 RootView 的 `preferredColorScheme` 控制；跟随系统时为 nil，高对比强制浅色

## 未实现（按分工留给后续）

- 页面与业务：对话页（P3）；记录、我的、使用指南已由 P4 接入
- P2：场景包、环节导航、常用语
- P3：听写、播报、大字牌、面对面、要点；全程文字的实际停麦/「文字直达」
- P4：本地 JSON 持久化、外观/字号/高对比已接入；真机验收待补
- App 图标素材已提供（`AppIcon-1024.png`，1024×1024、RGB 无 alpha），设备上可见需构建后确认

## 在 Mac 上打开

本仓库当前在 Windows 环境编写，无法执行 `xcodebuild` 或模拟器，请在 macOS + Xcode 16 上验证。

方式 A（XcodeGen）：

```bash
brew install xcodegen
cd ios
xcodegen generate
open Yizhen.xcodeproj
```

方式 B（不装 XcodeGen）：

1. Xcode 16 → New Project → iOS App
2. Product Name 填 `译诊`，Bundle ID `com.yizhen.app`，Interface `SwiftUI`，Language `Swift`，Minimum Deployment iOS 17
3. 删除模板生成的 `ContentView.swift` 与 `译诊App.swift`
4. 把 `Yizhen/` 下所有 `.swift` 与 `Assets.xcassets` 拖进工程（勾选 Copy items if needed、对应 target）
5. 运行

## 文件

```text
ios/
├─ project.yml                       XcodeGen 配置（com.yizhen.app / iOS 17 / 自动 Info.plist）
├─ README.md
└─ Yizhen/
   ├─ YizhenApp.swift                @main，注入 YZAppState，启动 RootView
   ├─ RootView.swift                 外壳：Tab / 路由 / 关闭与返回 / 0.12s 转场
   ├─ PlaceholderView.swift          占位页
   ├─ Shared/
   │  ├─ YZTheme.swift               颜色 / 字号 / 尺寸 / 阴影 + 主题与字号枚举
   │  ├─ YZModels.swift              场景 / 角色 / 消息 / 会话 / 术语 / Tab / 路由
   │  ├─ YZStores.swift              存储协议 + 内存实现
   │  ├─ YZAppState.swift            @Observable 全局状态与动作
   │  ├─ YZSampleData.swift          DEBUG 假数据（会话 / 常用语）
   │  └─ YZComponents.swift          9 个基础组件 + Toast 修饰器
   ├─ Views/
   │  ├─ HomeView.swift              静态首页与入口接线
   │  ├─ HeroCarousel.swift          4 张轮播 / 淡入 / 缩放 / 圆点
   │  └─ EmergencySignView.swift     红色紧急大字牌
   ├─ Preview/
   │  └─ ComponentGallery.swift      浅色 / 深色组件总览
   └─ Assets.xcassets/               YZ* 颜色集、AccentColor、AppIcon 1024 无 alpha
```