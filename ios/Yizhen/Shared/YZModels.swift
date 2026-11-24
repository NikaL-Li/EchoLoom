import Foundation

typealias YZScene = SceneKind
typealias YZTerm = Term

enum YZRole: String, Codable, Hashable, CaseIterable {
    case me
    case other

    var title: String {
        switch self {
        case .me: return "我"
        case .other: return "对方"
        }
    }
}

struct YZTurn: Identifiable, Codable, Hashable {
    var id: UUID
    var role: YZRole
    var text: String
    var status: String
    var date: Date

    init(
        id: UUID = UUID(),
        role: YZRole,
        text: String,
        status: String,
        date: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.status = status
        self.date = date
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct YZSession: Identifiable, Codable, Hashable {
    var id: UUID
    var scene: YZScene
    var subScene: String
    var startedAt: Date
    var endedAt: Date
    var turns: [YZTurn]

    init(
        id: UUID = UUID(),
        scene: YZScene,
        subScene: String,
        startedAt: Date,
        endedAt: Date,
        turns: [YZTurn]
    ) {
        self.id = id
        self.scene = scene
        self.subScene = subScene
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.turns = turns
    }

    var title: String {
        "\(scene.rawValue) · \(subScene)"
    }
}

enum YZTab: Hashable, CaseIterable {
    case home
    case records
    case profile

    var title: String {
        switch self {
        case .home: return "首页"
        case .records: return "记录"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .records: return "list.bullet.rectangle"
        case .profile: return "person"
        }
    }
}

enum YZRoute: Hashable {
    case talk(faceToFace: Bool)
    case phrases
    case session(UUID)
    case guide
}

enum YZTalkTab: String, CaseIterable, Hashable {
    case dialog
    case phrases

    var title: String {
        switch self {
        case .dialog: return "对话"
        case .phrases: return "常用语"
        }
    }
}

struct YZPendingSpeech: Equatable {
    let turnID: UUID
    let text: String
}

extension SceneKind {
    var isEmergency: Bool { self == .emergency }
}

extension YZRole {
    var isMine: Bool { self == .me }
}
