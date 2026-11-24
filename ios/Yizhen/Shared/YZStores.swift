import Foundation

protocol YZSessionStoring {
    func load() -> [YZSession]
    func save(_ sessions: [YZSession])
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
