import Foundation
import Observation

@Observable
final class YZAppState {
    var tab: YZTab = .home
    var route: YZRoute?
    var scene: YZScene = .medical
    var subScene: String = "问诊"
    var turns: [YZTurn] = []
    var sessions: [YZSession] = []
    var phrasesByKey: [String: [String]] = [:]

    var themeMode: YZThemeMode = .system
    var fontSize: YZFontSize = .normal
    var highContrast = false
    var textOnly = false
    var faceToFace = false
    var emergencySign = false
    var toast: String?

    @ObservationIgnored private let sessionStore: YZSessionStoring
    @ObservationIgnored private let phraseStore: YZPhraseStoring
    @ObservationIgnored private var talkStartedAt: Date?

    init(
        sessionStore: YZSessionStoring = YZMemorySessionStore(),
        phraseStore: YZPhraseStoring = YZMemoryPhraseStore()
    ) {
        self.sessionStore = sessionStore
        self.phraseStore = phraseStore
        self.sessions = sessionStore.load()
        self.phrasesByKey = phraseStore.load()
    }

    var todaySessionCount: Int {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDateInToday($0.endedAt) }.count
    }

    var phraseCount: Int {
        phrases(for: scene, subScene: subScene).count
    }

    func phrases(for scene: YZScene, subScene: String) -> [String] {
        phrasesByKey[Self.phraseKey(scene: scene, subScene: subScene)] ?? []
    }

    static func phraseKey(scene: YZScene, subScene: String) -> String {
        "\(scene.rawValue)|\(subScene)"
    }

    func selectTab(_ next: YZTab) {
        tab = next
        route = nil
    }

    func startTalk(faceToFace: Bool = false) {
        turns = []
        talkStartedAt = Date()
        self.faceToFace = faceToFace
        route = .talk(faceToFace: faceToFace)
    }

    func closeTalk() {
        if !turns.isEmpty {
            let session = YZSession(
                scene: scene,
                subScene: subScene,
                startedAt: talkStartedAt ?? turns.first?.date ?? Date(),
                endedAt: turns.last?.date ?? Date(),
                turns: turns
            )
            sessions.append(session)
            sessionStore.save(sessions)
        }
        turns = []
        talkStartedAt = nil
        faceToFace = false
        route = nil
        tab = .home
    }

    func openPhrases() {
        route = .phrases
    }

    func openSession(_ id: UUID) {
        route = .session(id)
    }

    func openGuide() {
        route = .guide
    }

    func closeRoute() {
        route = nil
    }

    func showEmergencySign() {
        emergencySign = true
    }

    func hideEmergencySign() {
        emergencySign = false
    }

    func session(with id: UUID) -> YZSession? {
        sessions.first { $0.id == id }
    }
}

#if DEBUG
extension YZAppState {
    static var preview: YZAppState {
        YZAppState(
            sessionStore: YZMemorySessionStore(sessions: YZSampleData.sessions),
            phraseStore: YZMemoryPhraseStore(phrases: YZSampleData.phrases)
        )
    }
}
#endif