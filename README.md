# 译诊 · 听障人士双向沟通 App（P1–P4 整合版）

一个 iOS 17+ / SwiftUI 原生应用：把对方说的话转成文字，把使用者想说的话播出来，也能把手机变成大字牌。无第三方依赖。

## 直接运行

1. 用 **Xcode 16** 打开 `ios/Yizhen.xcodeproj`。
2. 选择 `Yizhen` target → **Signing & Capabilities**，真机运行时选择自己的 Team。
3. 选择 iPhone 模拟器运行。语音听写建议在真机测试，模拟器的中文语音识别与麦克风能力有限。
4. 第一次点「听对方说」时才申请麦克风与语音识别权限；拒绝后文字输入仍可用。

如果以后增删了源文件，也可以用 `ios/project.yml` 重新生成工程（需要安装 XcodeGen）：

```bash
cd ios
xcodegen generate
```

## 已整合的四个模块

| 模块 | 内容 | 位置 |
|---|---|---|
| P1 | 外壳、设计系统、首页、最终集成 | `ios/Yizhen/RootView.swift`、`Shared/`、`Features/Home/` |
| P2 | 五个场景包、环节导航、可播句、我的常用语、术语提示 | `Features/Scenes/` |
| P3 | 对话页、听写、播报、大字牌、面对面、生成要点 | `Features/Talk/` |
| P4 | 本机会话存储、记录、会话详情、我的、外观设置、指南与权限 | `Features/Records/`、`Features/Profile/`、`Features/Guide/` |

## 主要能力

- 首页：今日对话、柔和轮播图、开始对话、一键亮牌、面对面、我的常用语。
- 场景：就医步骤条；点餐 / 出行 / 办事 / 紧急下划线标签；每环节 6 句内置句；110 条术语。
- 对话：消息卡片、可播句、输入抽屉、语音听写、系统播报、消息重播/复制、全屏大字。
- 大字牌：从首页、对话页「全屏」、消息卡片进入；支持横屏、自动放大、防锁屏。
- 面对面：上下分屏，对方面板旋转 180°，新消息自动滚到底。
- 要点：总结「我说的 / 对方说的 / 下一步」三条，可复制；会话详情也能生成。
- 记录：今天 / 近 7 天 / 本月 / 累计；最多保留最近 20 次；会话详情可导出纯文本。
- 我的：常用语入口、使用指南、跟随系统/浅色/深色、18/24/30 字号、高对比、全程文字。
- 隐私：麦克风与语音识别只在真正使用时申请；录音和转写不由 App 保存或上传。

## 自适应与可访问性

- iPhone 满宽、iPad 居中，正文最大宽度 430。
- 布局使用自适应网格、`ViewThatFits`、可滚动内容和安全区，适配小屏、大字号和横屏。
- 字体同时受系统动态字体与 18/24/30 三档设置影响，并设有保护性上限避免破版。
- 深色模式使用 Asset Catalog 颜色集；高对比模式白底黑字黑边、去阴影与渐变，选中态反色。
- 尊重「减少动态效果」：关闭轮播、缩放、上浮、录音光边，只保留淡入。
- 所有可点击控件至少 44pt；主要图标按钮均有 VoiceOver 标签。
- 录音、播报、权限失败、识别失败都有可见文字提示与必要的 VoiceOver 播报。

## 数据位置

- 会话：`Application Support/YiZhen/sessions.json`，最近 20 次，原子写入，已排除 iCloud 备份。
- 自定义常用语：`UserDefaults` key `yizhen.myPhrases.v1`，按 `场景|环节` 分组，最多 60 字。
- 设置：`UserDefaults` keys `yz.appearance.mode`、`yz.typography.fontSize`、`yz.display.highContrast`、`yz.voice.textOnly`。
- 累计次数：`UserDefaults` key `yz.sessions.totalSavedCount`。

## 目录

```text
译诊/
├─ README.md
├─ docs/
│  └─ 整合审查报告.md
└─ ios/
   ├─ Yizhen.xcodeproj/
   ├─ project.yml
   ├─ Info.plist
   └─ Yizhen/
      ├─ YizhenApp.swift
      ├─ RootView.swift
      ├─ Shared/
      ├─ Features/{Home,Scenes,Talk,Records,Profile,Guide}/
      ├─ Preview/
      └─ Resources/Assets.xcassets/
```

## 素材说明

`Assets.xcassets/hero1…hero4` 目前是自绘的柔和渐变占位图，避免空白和版权问题。拿到团队照片后，直接替换四个 imageset 中的 `heroN.jpg / heroN@2x.jpg / heroN@3x.jpg` 即可，名字不要改。AppIcon 也是可直接替换的 1024×1024 占位图标。

## 验证状态

本工程已在 Linux 环境完成静态校验：44 个 Swift 文件语法通过、无重复类型、场景数据完整（5 场景 / 20 环节 / 120 句 / 110 条唯一术语）、Asset JSON 与 Info.plist/Scheme 可解析、Xcode 工程 44 个源码引用与磁盘文件一一对应。由于当前环境没有 Xcode 与 SwiftUI 运行时，**未执行真正的 Xcode 编译和真机语音测试**；请在 Xcode 16 中先跑一次模拟器，再到真机验证听写与播报。

详细审查结论、问题修复和真机测试清单见 `docs/整合审查报告.md`。