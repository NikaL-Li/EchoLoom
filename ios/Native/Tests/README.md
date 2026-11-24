# 原生版数据逻辑回归检查

在 `ios/Native` 下执行：

```sh
xcrun swiftc -target arm64-apple-macosx14.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)" -module-cache-path /tmp/ylct-test-modules Sources/ServiceOrigin.swift Sources/Models.swift Tests/main.swift -o /tmp/ylct-domain-checks
/tmp/ylct-domain-checks
```

覆盖真实日期统计、跨月/跨年、夏令时、持久化编码、手机号与房号隔离、取餐码与尾号隔离。测试只使用内存中的虚构数据，不访问账号、不请求 API、不修改真实记录。

覆盖首页/送餐/取餐入口默认模式、完整可拨号码与隐藏/残缺号码、中文地图地址编码、骑行与旧系统地图链接、地址确认语句和备注隔离，以及播放生命周期、连续采样、消息来源与重播路由。共 117 项业务检查。

## 自定义常用语

双声音频保存、修改、删除、损坏文件、重试与取消检查：

```sh
xcrun swiftc -target arm64-apple-macosx14.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)" -module-cache-path /tmp/ylct-test-modules Sources/ServiceOrigin.swift Sources/CustomPhrases.swift Tests/CustomPhraseTests.swift -o /tmp/ylct-phrase-checks
/tmp/ylct-phrase-checks
```

使用临时目录和已有男女声 WAV，不接触真实常用语，不发出在线合成请求。

排序检查包含：自定义与系统混排、跨模式筛选、重启持久化、男女声文件逐字节保留、零合成请求、修改 / 新增 / 删除后的顺序、拒绝重复 / 遗漏 / 陌生 ID，以及损坏排序文件保护。也覆盖实际文件写入失败后的顺序保留与恢复重试。常用语共 61 项检查。

## 内置静态音频

所有 16 条固定回复的男女声音频必须存在、能解码，且男女声不能是同一个文件。支持以编译后的 App 包作为参数，验证音频确实被打包，而不是只存在于源码目录。

```sh
xcrun swiftc -target arm64-apple-macosx14.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)" -module-cache-path /tmp/ylct-test-modules Sources/ServiceOrigin.swift Sources/CustomPhrases.swift Tests/BundledReplyAudioTests.swift -o /tmp/ylct-bundle-checks
/tmp/ylct-bundle-checks
# 可选：/tmp/ylct-bundle-checks /absolute/path/to/YLCTNative.app
python3 Tests/prepare_bundled_replies.py
```

新增的 6 个面对面音频使用实际 MiMo 接口生成；生成工具复用 App 的 URLSession 请求和 WAV 校验。维护工具不加入 App target。新增固定文案时显式运行 `python3 Tests/prepare_bundled_replies.py --generate`，随后运行 `python3 Tests/register_bundled_replies.py`，不会重写权限配置。

## 即时系统语音与界面

临时输入直接交给系统语音，不先渲染整句。系统语音没有可靠总时长，因此显示连续活动条和已播时间，在系统真正结束时才显示播报结束；MiMo 文件使用播放器真实时长和连续进度。旧 `LocalSpeechAudio` 工具不再被播放路径调用。

`PlaybackProgressUITests` 覆盖停止、重播、唯一完整进度区、常用回复在键盘出现后仍常驻、相同文字按来源使用不同播放路径，以及全新离线状态下三条面对面内置回复的男女声播放。`CustomPhraseUITests.testAddingOnlyShowsSuccessAndDoesNotPlayAudio` 验证添加后只有成功提示，无自动试听；部分生成失败不能显示成功。

## 通话开场

在本目录将 Sources/ServiceOrigin.swift、Sources/Models.swift、Sources/UniversalModels.swift 和 Tests/OpeningTests.swift 一起编译成 macOS 命令行程序，运行可覆盖等待、接通、注入未就绪、超时、第二路、保留、挂断、不重复播报，以及旧数据兼容与号码匹配。UniversalFlowUITests 中的 testNewDefaultOpeningSavedOffline 使用模拟合成服务验证双声音频的保存流程，testOpeningContactWallpaperAndDefault 使用模拟器通讯录与模拟拨号，不会拨出电话。真机蜂窝电话和对端听感需单独验证。
