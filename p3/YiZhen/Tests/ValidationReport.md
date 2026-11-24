# 验证记录

## 当前环境

实现在 Windows 工作区完成，无法运行 Xcode、iOS 模拟器、Instruments 与 VoiceOver。以下标记「待 macOS」的项目必须在 macOS + Xcode 16 + iOS 17 模拟器上执行。

## 本轮设计稿对齐结果

- 视觉基线切换为设计稿 `index(16).html` 最终令牌（738–760 行）；旧值 `#eef2f8/#101828/#1a4fbf/#2F6BFF` 已从代码与资源中清除。
- 对话页改为三段：talkbar（工具行 / 场景行 / 二级行）→ 内容区（分段 + 双内容常驻）→ dock 浮层。
- 场景改为生活场景「就医 / 点餐 / 出行 / 办事 / 紧急」；就医二级为「挂号 / 问诊 / 检查 / 取药 / 缴费」，默认「问诊」。
- 二级导航支持 step（就医）与 tab（其余场景）两种形态，可点击切换并刷新句表。
- 常用语改为 6 条静态句表，含空态与「共 N 条 · 点一句就能播」页脚；点击仅提示，不播报。
- 底部改为 430 上限毛玻璃 dock：三按钮 1:1:1、56 高、15/700、无图标；紧急条实心红白字、文案无句号。
- 消息卡片增加 1pt 描边、通高方向边条、对方标签行、我方 plain 状态 pill、11pt 操作文字。
- 删除 `DialogHeader`、`DialogTopBar`、`PhaseNavRow`、`BottomActionBar`、`PhrasePlaceholderView`。

## 已完成的结构校验

- `YiZhen.xcodeproj`：`tools/validate-project.js` 校验通过 —— 164 个对象、0 缺失声明、0 未引用对象、括号平衡；3 个 target。
- Swift 文件 54 个（App 48、单元测试 5、UI 测试 1），括号平衡检查通过。
- 语义色 Asset 32 组（原 20 + 新增 12），JSON 结构校验通过。
- 旧 identifier、旧色值、旧组件类型静态扫描零命中。
- `Info.plist` 无任何权限键；无 `AVFoundation`/`AVSpeechSynthesizer`/`UIPasteboard`/`URLSession`/`UserDefaults`/`tel://`。

## 待 macOS 验证

| 项 | 命令 / 方式 | 状态 |
| --- | --- | --- |
| 编译 | `xcodebuild -project YiZhen.xcodeproj -scheme YiZhen -sdk iphonesimulator build` | 待 macOS |
| 单元测试 | `xcodebuild test -scheme YiZhen -only-testing:YiZhenTests` | 待 macOS |
| UI 测试 | `xcodebuild test -scheme YiZhen -only-testing:YiZhenUITests` | 待 macOS |
| 预览 P1–P12 | Xcode Preview 逐组截图归档 | 待 macOS |
| 像素对照 | 取色器核对话页 50 项；标注 C6 折中项 | 待 macOS |
| VoiceOver | 焦点顺序、卡片合并朗读、句行合并 | 待 macOS / 真机 |
| 深色 / 灰度 / 减少动态 | 模拟器切换与截图 | 待 macOS |
| 320pt + AX3 | 三按钮两行、场景/二级横滑、紧急条换行 | 待 macOS / 真机 |
| 性能 | 50 条滚动 60fps（talkbar + dock 双 blur） | 待 macOS |

## 已知折中（C6）

设计稿对话页主内容为常用语句表，没有「对话 / 常用语」分段与消息流。本期按任务默认口径保留分段与 3 条消息流，并隔离在 `ContentComposition`；若改为严格照设计稿，只需删除该组合层并调整内容槽位，卡片、句表、dock 不受影响。
## 消息卡片专项（本轮）

- 卡片主体与按钮手势分层：卡片 tap 只挂「标签 + 主句」主体层；底部左区（含 pill）用无 AX 焦点几何 tap；按钮子树内无卡片手势。
- 操作行双层：视觉高 30、圆角 8、水平 6、视觉间距 2；热区 ≥44×44，重播向左、复制向右非对称外扩，两热区边界相接不重叠。
- 卡片点击占位：`openCard` → Toast「全屏大字牌筹备中」；复制/重播沿用「复制功能筹备中」「播报功能筹备中」，均不写剪贴板、不启语音。
- 对方标签「医生 · HH:mm」/「对方 · HH:mm」；我方状态 pill 仅 plain 可达；对方无 pill。
- hint 文案统一为「全屏大字牌筹备中」；主体无 button trait。
- 预览新增 P13–P17；UI 测试新增 4 条（卡片点击、按钮不串、热区、间距）；模型测试新增 3 条；Toast 契约测试新增 3 条。
- Windows 已完成：括号平衡、链路扫描（`onTap: {}` 零残留）、无音频/剪贴板/网络/权限、工程结构校验。
- 待 macOS：编译、P1–P17 渲染截图、XCUITest frame 断言、视觉间距 2 像素取证、缝隙点击、VoiceOver 三焦点、灰度/深色/减少动态。
## 我要说输入抽屉专项（本轮）

- 点击 dock「我要说」打开自定义底部抽屉：上圆角 24、38×4 把手、标题 16/800、关闭 12/400（44 热区）、输入框 88–150、发送 56/20/15-700、两行 11/1.5 说明。
- 输入用 UIKit `UITextView` 桥接：Enter 发送不换行、IME 组字不发送、粘贴多行保留、500 字上限、焦点描边、动态高度。
- 发送链：`YZAppState.sendMineText` 追加恰好 1 条我方「文字直达」消息；`DialogViewModel` 清空草稿、保持抽屉、设置一次性滚动锚点；防连点由空草稿 + `isSubmitting` 守卫。
- Toast 从 `DockLayer` 上移到 `DialogPage` 顶层 overlay，抽屉打开时位于抽屉上方；dock 在抽屉打开时不可点、不可聚焦。
- 发送后内容预留抬升为键盘高 + 抽屉高 + 12，`MessageListView` 用一次性 `scrollTargetID` 跟随新卡；进入页面仍不滚动。
- 预览新增 P18–P22；UI 测试新增打开/关闭、空禁用、发送追加、Enter 发送、关闭丢弃草稿、说明文本；单元测试新增 send/VM/令牌。
- 明确不做：TTS/语音识别/麦克风/权限/网络/剪贴板/持久化/「我的」跳转/手语识别。
- Windows 已完成：工程结构、58 文件括号平衡、颜色/尺寸/资源双写、越界 API 扫描。
- 待 macOS：编译、键盘与 IME、焦点恢复、抽屉动画、发送滚动、P18–P22 截图、XCUITest。