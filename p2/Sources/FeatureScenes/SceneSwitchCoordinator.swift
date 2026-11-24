import Foundation

public enum YZSpeaker: String, Equatable, Sendable {
    case patient
    case other
}

public struct YZConversationTurn: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let speaker: YZSpeaker
    public let text: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        speaker: YZSpeaker,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.createdAt = createdAt
    }
}

public struct YZSceneSession: Identifiable, Sendable {
    public let id: UUID
    public let scene: SceneKind
    public let sub: String
    public let turns: [YZConversationTurn]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        scene: SceneKind,
        sub: String,
        turns: [YZConversationTurn],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scene = scene
        self.sub = sub
        self.turns = turns
        self.createdAt = createdAt
    }
}

public protocol YZSessionStoring {
    func save(_ session: YZSceneSession) throws
}

public struct YZNoopSessionStore: YZSessionStoring {
    public init() {}

    public func save(_ session: YZSceneSession) throws {}
}

public struct YZSceneSwitchOutcome: Equatable, Sendable {
    public let savedSession: Bool
    public let previousScene: SceneKind
    public let previousSub: String
    public let scene: SceneKind
    public let sub: String
    public let dividerText: String?
    public let saveError: String?

    public init(
        savedSession: Bool,
        previousScene: SceneKind,
        previousSub: String,
        scene: SceneKind,
        sub: String,
        dividerText: String?,
        saveError: String?
    ) {
        self.savedSession = savedSession
        self.previousScene = previousScene
        self.previousSub = previousSub
        self.scene = scene
        self.sub = sub
        self.dividerText = dividerText
        self.saveError = saveError
    }
}

public struct YZSceneSwitching: Sendable {
    public private(set) var scene: SceneKind
    public private(set) var sub: String
    public private(set) var dividerText: String?

    public init(scene: SceneKind = .medical) {
        self.scene = scene
        self.sub = SceneCatalog.defaultSub(for: scene)
        self.dividerText = nil
    }

    @discardableResult
    public mutating func switchScene(
        to newScene: SceneKind,
        turns: [YZConversationTurn],
        store: any YZSessionStoring = YZNoopSessionStore(),
        now: Date = Date()
    ) -> YZSceneSwitchOutcome {
        let previousScene = scene
        let previousSub = sub

        var savedSession = false
        var saveError: String?

        if !turns.isEmpty {
            let session = YZSceneSession(
                scene: previousScene,
                sub: previousSub,
                turns: turns,
                createdAt: now
            )
            do {
                try store.save(session)
                savedSession = true
            } catch {
                saveError = error.localizedDescription
            }
        }

        scene = newScene
        sub = SceneCatalog.defaultSub(for: newScene)
        dividerText = "— \(scene.rawValue) · \(sub) 新会话 —"

        return YZSceneSwitchOutcome(
            savedSession: savedSession,
            previousScene: previousScene,
            previousSub: previousSub,
            scene: scene,
            sub: sub,
            dividerText: dividerText,
            saveError: saveError
        )
    }

    @discardableResult
    public mutating func switchSub(to newSub: String) -> Bool {
        guard SceneCatalog.subs(for: scene).contains(newSub) else { return false }
        sub = newSub
        dividerText = nil
        return true
    }

    public func phrases() -> [String] {
        SceneCatalog.phrases(for: scene, sub: sub)
    }

    public func terms() -> [Term] {
        SceneCatalog.terms(for: scene)
    }

    public func termHint(for text: String) -> Term? {
        TermMatcher.match(text, in: terms())
    }
}