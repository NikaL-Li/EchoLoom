import Foundation

protocol YZSessionStoring {
    func load() -> [YZSession]
    func save(_ sessions: [YZSession])
}

protocol YZPhraseStoring {
    func load() -> [String: [String]]
    func save(_ phrases: [String: [String]])
}

final class YZMemorySessionStore: YZSessionStoring {
    private var sessions: [YZSession]

    init(sessions: [YZSession] = []) {
        self.sessions = sessions
    }

    func load() -> [YZSession] {
        sessions
    }

    func save(_ sessions: [YZSession]) {
        self.sessions = sessions
    }
}

final class YZMemoryPhraseStore: YZPhraseStoring {
    private var phrases: [String: [String]]

    init(phrases: [String: [String]] = [:]) {
        self.phrases = phrases
    }

    func load() -> [String: [String]] {
        phrases
    }

    func save(_ phrases: [String: [String]]) {
        self.phrases = phrases
    }
}