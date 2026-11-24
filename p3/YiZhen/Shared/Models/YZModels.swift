import Foundation

enum YZMessageDirection: String, Equatable, Hashable {
    case mine
    case other
}

enum YZStatusKind: String, Equatable, Hashable {
    case plain
    case ok
    case fail
}

enum YZNavStyle: String, Equatable, Hashable {
    case step
    case tab
}

struct YZMessage: Identifiable, Equatable, Hashable {
    let id: String
    let direction: YZMessageDirection
    let text: String
    let statusText: String
    let createdAt: Date
    let replayable: Bool
    let copyable: Bool
    let isKeyPoint: Bool

    init(
        id: String,
        direction: YZMessageDirection,
        text: String,
        statusText: String,
        createdAt: Date,
        replayable: Bool = true,
        copyable: Bool = true,
        isKeyPoint: Bool = false
    ) {
        self.id = id
        self.direction = direction
        self.text = text
        self.statusText = statusText
        self.createdAt = createdAt
        self.replayable = replayable
        self.copyable = copyable
        self.isKeyPoint = isKeyPoint
    }

    var statusKind: YZStatusKind {
        switch statusText {
        case "已播报": return .ok
        case "播报失败": return .fail
        default: return .plain
        }
    }
}

struct YZScene: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let order: Int
    let isSelected: Bool
    let isEmergency: Bool
}

struct YZPhase: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let order: Int
    let isCurrent: Bool
}

struct YZScenePack: Identifiable, Equatable {
    let scene: YZScene
    let navStyle: YZNavStyle
    let phases: [YZPhase]

    var id: String { scene.id }
}

struct YZPhrase: Identifiable, Equatable, Hashable {
    let id: String
    let text: String
    let placeholder: Bool
}

struct YZEmergencyBanner: Equatable {
    let text: String
    let visible: Bool
    let interactive: Bool
}

struct YZDialogSession: Equatable {
    let scenes: [YZScene]
    let phases: [YZPhase]
    let messages: [YZMessage]
    let phrases: [YZPhrase]
}

enum YZDialogView: String, Hashable, CaseIterable {
    case dialog
    case phrases

    var title: String {
        switch self {
        case .dialog: return "对话"
        case .phrases: return "常用语"
        }
    }
}