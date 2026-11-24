import Foundation

enum YZScene: String, Codable, CaseIterable, Identifiable {
    case medical = "就医"
    case dining = "点餐"
    case transit = "出行"
    case service = "办事"
    case emergency = "紧急"

    var id: String { rawValue }
}

enum YZRole: String, Codable, Hashable {
    case me
    case other
}

struct YZTurn: Identifiable, Codable, Hashable {
    var id = UUID()
    var role: YZRole
    var text: String
    var status: String
    var date = Date()
}

struct YZSession: Identifiable, Codable, Hashable {
    var id = UUID()
    var scene: YZScene
    var subScene: String
    var startedAt: Date
    var endedAt: Date
    var turns: [YZTurn]
}

struct YZTerm: Identifiable, Codable, Hashable {
    var id: String
    var category: String
    var standard: String
    var colloquial: String
    var ask: String
}

enum YZTab: Hashable, CaseIterable {
    case home
    case records
    case profile
}

enum YZRoute: Hashable {
    case talk(faceToFace: Bool)
    case phrases
    case session(UUID)
    case guide
}