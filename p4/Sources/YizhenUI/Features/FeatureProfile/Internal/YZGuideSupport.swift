import Foundation
import SwiftUI

enum YZGuideStyle {
    static var pageBackground: Color { YZTheme.bg }
    static var cardBackground: Color { YZTheme.card }
    static var textPrimary: Color { YZTheme.ink }
    static var textSecondary: Color { YZTheme.ink2 }
    static var textTertiary: Color { YZTheme.ink3 }
    static var separator: Color { YZTheme.line }
    static var primary: Color { YZTheme.blue }
    static var primaryFill: Color { YZTheme.blueFill }
    static var primarySoft: Color { YZTheme.blueSoft }
    static var mutedSurface: Color { YZTheme.bg }
    static var successFill: Color { YZTheme.greenFill }
    static var danger: Color { YZTheme.danger }
}

enum YZGuideFont {
    static var pageTitle: Font { YZTheme.fontPageTitle }
    static var sectionTitle: Font { YZTheme.fontRowTitle }
    static var body: Font { YZTheme.fontBody }
    static var caption: Font { YZTheme.fontCaption }
    static var tag: Font { YZTheme.fontTag }
    static var badge: Font { YZTheme.fontPill }
    static var stepNumber: Font { YZTheme.fontTag }
}

struct YZGuideStep: Identifiable {
    let id: Int
    let title: String
    let operation: String
    let expectation: String
    let stuck: String
}

enum YZGuideCopy {
    static let pageTitle = "使用指南"
    static let permissionTitle = "权限"
    static let microphone = "麦克风"
    static let speechRecognition = "语音识别"
    static let authorized = "已允许"
    static let denied = "未允许"
    static let notDetermined = "未询问"
    static let loading = "读取中"
    static let failed = "读取失败"
    static let retry = "重试"
    static let openSettings = "去设置"
    static let restrictedNote = "系统限制"
    static let permissionReadFailed = "暂时无法读取权限状态，请稍后重试"
    static let settingsFailed = "无法打开系统设置，请手动打开设置找到译诊"
    static let notDeterminedHint = "先在对话页点一次『听对方说』完成授权"
    static let footer = "只申请真正用到的权限；没有用到的相册、定位不会申请。"
    static let operation = "操作"
    static let expectation = "预期"
    static let stuck = "卡住时"

    static let steps: [YZGuideStep] = [
        YZGuideStep(
            id: 1,
            title: "打开首页",
            operation: "打开「译诊」，停在首页。",
            expectation: "能看到「今日对话」和「开始对话」。",
            stuck: "如果首页一直空白，退出应用再打开一次；仍然空白就重启手机后再试。"
        ),
        YZGuideStep(
            id: 2,
            title: "点开始对话",
            operation: "点首页的「开始对话」。",
            expectation: "进入对话页，能看到「听对方说」按钮。",
            stuck: "如果点了没反应，返回首页再点一次；还是进不去，请更新到最新版本。"
        ),
        YZGuideStep(
            id: 3,
            title: "点听对方说",
            operation: "把手机递给对方，点「听对方说」。",
            expectation: "第一次会询问麦克风和语音识别；允许后，对方说的话会变成文字。",
            stuck: "如果一直没有文字，先看本页「权限」是否显示「已允许」；对方声音太小时，把手机靠近一些。"
        ),
        YZGuideStep(
            id: 4,
            title: "点快捷短语",
            operation: "点对话页的「快捷短语」，选一句要说的。",
            expectation: "这句话会出现在对话里，可以给对方看，也可以播放给对方听。",
            stuck: "如果列表是空的，先到「我的」→「我的常用语」添加；暂时不加，就先点「听对方说」继续。"
        ),
        YZGuideStep(
            id: 5,
            title: "点一键亮牌",
            operation: "点对话页的「一键亮牌」。",
            expectation: "屏幕会变成大字牌，把手机举给对方看。",
            stuck: "如果字牌没有出现，返回对话页再点一次；看完点「收起」回到对话。"
        ),
    ]
}

enum YZPermissionDisplayStatus: Equatable {
    case authorized
    case denied
    case notDetermined

    var text: String {
        switch self {
        case .authorized:
            return YZGuideCopy.authorized
        case .denied:
            return YZGuideCopy.denied
        case .notDetermined:
            return YZGuideCopy.notDetermined
        }
    }
}

enum YZGuidePermissionRowState: Equatable {
    case loading
    case resolved(YZPermissionDisplayStatus, restricted: Bool)
    case failed

    var displayStatus: YZPermissionDisplayStatus? {
        if case .resolved(let status, _) = self {
            return status
        }
        return nil
    }

    var isRestricted: Bool {
        if case .resolved(_, let restricted) = self {
            return restricted
        }
        return false
    }
}

protocol YZGuidePermissionQuerying {
    func microphoneStatus() -> YZGuidePermissionRowState
    func speechRecognitionStatus() -> YZGuidePermissionRowState
    func openApplicationSettings() -> Bool
}