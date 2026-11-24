import Foundation
import Observation

@MainActor
@Observable
final class YZAppState {
    var tab: YZTab = .home
    var route: YZRoute?

    var scene: YZScene = .medical
    var subScene: String = SceneCatalog.defaultSub(for: .medical)
    var turns: [YZTurn] = []
    var sessions: [YZSession] = []
    var totalSavedCount: Int = 0
    var dividerText: String?
    var customPhrasesRevision: Int = 0

    var themeMode: YZThemeMode = .system
    var fontSize: YZFontSize = .normal
    var highContrast = false
    var textOnly = false
    var emergencySign = false
    var toast: String?

    var pendingSpeech: YZPendingSpeech?

    @ObservationIgnored private let sessionStore: YZSessionStoring
    @ObservationIgnored private let customPhraseStore: any YZCustomPhraseStoring
    @ObservationIgnored private var talkStartedAt: Date?
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    private static let totalCountKey = "yz.sessions.totalSavedCount"
    private static let maximumSessionCount = 20

    init(
        sessionStore: YZSessionStoring = YZFeatureSessionStore(),
        customPhraseStore: any YZCustomPhraseStoring = YZUserDefaultsPhraseStore()
    ) {
        self.sessionStore = sessionStore
        self.customPhraseStore = customPhraseStore
        self.sessions = Self.latest(sessionStore.load())
        self.totalSavedCount = max(
            UserDefaults.standard.integer(forKey: Self.totalCountKey),
            sessions.count
        )
        UserDefaults.standard.set(totalSavedCount, forKey: Self.totalCountKey)
        YZProfileSettingsPersistence.load(into: self)
    }


    var todaySessionCount: Int {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDateInToday($0.endedAt) }.count
    }

    var phraseCount: Int {
        _ = customPhrasesRevision
        return phrases(for: scene, subScene: subScene).count
    }

    func phrases(for scene: YZScene, subScene: String) -> [String] {
        _ = customPhrasesRevision
        let builtIn = SceneCatalog.phrases(for: scene, sub: subScene)
        let custom = (try? customPhraseStore.customPhrases(scene: scene, sub: subScene)) ?? []
        guard !custom.isEmpty else { return builtIn }

        var seen = Set(builtIn)
        var merged = builtIn
        for item in custom where !seen.contains(item) {
            merged.append(item)
            seen.insert(item)
        }
        return merged
    }

    func customPhrases(for scene: YZScene, subScene: String) -> [String] {
        (try? customPhraseStore.customPhrases(scene: scene, sub: subScene)) ?? []
    }

    var terms: [YZTerm] {
        SceneCatalog.terms(for: scene)
    }

    func session(with id: UUID) -> YZSession? {
        sessions.first { $0.id == id }
    }


    func selectTab(_ next: YZTab) {
        tab = next
        route = nil
    }

    func startTalk(faceToFace: Bool = false) {
        if !turns.isEmpty {
            commitCurrentSession()
        }
        dividerText = nil
        talkStartedAt = Date()
        route = .talk(faceToFace: faceToFace)
    }

    func startTalk(withPhrase text: String, subScene: String? = nil) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        startTalk()
        if let subScene, SceneCatalog.subs(for: scene).contains(subScene) {
            self.subScene = subScene
            dividerText = nil
        }
        let id = appendTurn(
            role: .me,
            text: value,
            status: textOnly ? "文字直达" : "待播报"
        )
        if !textOnly {
            pendingSpeech = YZPendingSpeech(turnID: id, text: value)
        }
    }

    func closeTalk() {
        commitCurrentSession()
        dividerText = nil
        route = nil
        tab = .home
    }

    func switchScene(to next: YZScene) {
        guard next != scene else { return }
        commitCurrentSession()
        scene = next
        subScene = SceneCatalog.defaultSub(for: next)
        dividerText = "— \(next.rawValue) · \(subScene) 新会话 —"
        talkStartedAt = Date()
    }

    func switchSubScene(to next: String) {
        guard next != subScene, SceneCatalog.subs(for: scene).contains(next) else { return }
        subScene = next
        dividerText = nil
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


    @discardableResult
    func appendTurn(role: YZRole, text: String, status: String) -> UUID {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let turn = YZTurn(
            role: role,
            text: value,
            status: status,
            date: max(Date(), turns.last?.date ?? .distantPast)
        )
        turns.append(turn)
        return turn.id
    }

    func updateTurnStatus(id: UUID, status: String) {
        guard let index = turns.firstIndex(where: { $0.id == id }) else { return }
        turns[index].status = status
    }

    func takePendingSpeech() -> YZPendingSpeech? {
        defer { pendingSpeech = nil }
        return pendingSpeech
    }

    func reloadCustomPhrases() {
        customPhrasesRevision += 1
    }


    private func commitCurrentSession() {
        let cleanTurns = turns.filter { !$0.trimmedText.isEmpty }
        guard !cleanTurns.isEmpty else {
            turns = []
            talkStartedAt = nil
            return
        }

        let session = YZSession(
            scene: scene,
            subScene: subScene,
            startedAt: talkStartedAt ?? cleanTurns.first?.date ?? Date(),
            endedAt: cleanTurns.last?.date ?? Date(),
            turns: cleanTurns
        )

        sessions.append(session)
        sessions = Self.latest(sessions)
        totalSavedCount += 1
        UserDefaults.standard.set(totalSavedCount, forKey: Self.totalCountKey)
        sessionStore.save(sessions)

        turns = []
        talkStartedAt = nil
        pendingSpeech = nil
    }

    private static func latest(_ sessions: [YZSession]) -> [YZSession] {
        Array(
            sessions
                .sorted { $0.endedAt > $1.endedAt }
                .prefix(maximumSessionCount)
        )
    }


    func showToast(_ message: String, duration: TimeInterval = 1.8) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, !Task.isCancelled else { return }
            if self.toast == message {
                self.toast = nil
            }
        }
    }
}
