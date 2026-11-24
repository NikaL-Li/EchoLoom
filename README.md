# 译声 · EchoLoom 3.0

为听障人士设计的 iPhone 沟通工具。打开「沟通」可以打字让手机说、看面对面字幕，或把手机递给对方轮流打字。电话辅助提供拨号、常用联系人、静态语音开场；通话对端的字幕由 iPhone 系统提供，应用不读取对端音轨。

- **离线可用**：双方打字、沟通卡、已保存的场景和对话、内置 16 句常用语的男女声，以及已经生成的自定义语音。临时输入由本机系统语音播报。
- **需要联网**：首次生成自定义短语的两种声音、更新天气和四城壁纸、骑手模式的截图识别。麦克风及语音识别能力以设备权限及系统支持为准。
- **资料**：场景和对话需主动保存。自定义语音只在两种声音都准备好后保存；生成时不会自动播放。应用不保存现场或通话录音。

## 团队与版本

[版本沿革](CHANGELOG.md)记录了从「译诊」网页到「译声」iPhone 应用的四份源码快照。[贡献者](AUTHORS.md)按阶段署名；后续开发见[协作流程](CONTRIBUTING.md)。

## 编译 iOS 应用

需要 macOS、Xcode 和 iOS SDK，最低运行系统 iOS 18.2。本次使用 Xcode 的 iOS 27.2 SDK 构建。打开 `ios/Native/译声.xcodeproj`，选 iPhone 模拟器运行。真机安装需要在 Signing & Capabilities 中选择自己的签名团队；GitHub Release 附件为**未签名**的 iPhoneOS Release 包。它不能直接安装，也不能直接提交 App Store Connect。

用源码重建未签名 IPA：

```sh
python3 scripts/release.py ipa /tmp/yisheng-release
```

应用标识沿用 `com.ylct.universal`，未更改 2.x 的资料保存位置。不要卸载旧版来升级，否则会删除应用的本地数据。

## 源码与自托管

| 目录 | 内容 |
| --- | --- |
| ios/Native | 原生应用、正式工程、模拟器测试工程、功能与音频测试 |
| backend | 适配原生客户端的可选 API 服务，使用说明见本目录 README |
| wallpaper | 四城图库、每日生成任务、部署配置、照片归属清单与测试 |
| scripts | 从干净源码生成源码 ZIP 或未签名 IPA 的工具 |

默认连接应用配置的 HTTPS 服务。自托管时，在 `ios/Native/Sources/Info.plist` 修改 `YSServiceOrigin`，并同步 `project.yml`；语音、天气、截图识别和远程相册共用这个地址。密钥只配置在服务端。详细验证步骤在 `ios/Native/Tests/README.md`。原项目许可、照片及其他素材的出处见 `NOTICES.md`。
