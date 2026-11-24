import Foundation

/// 落盘契约 DTO。字段名与 spec 6.3 一一对应，不随 P1 模型改名而变化。
struct YZSentenceDTO: Codable, Sendable, Equatable {
    let speaker: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case speaker
        case text
    }

    init(speaker: String, text: String) {
        self.speaker = speaker
        self.text = text
    }
}

struct YZSessionDTO: Codable, Sendable, Equatable {
    let id: String
    let scenario: String
    let phase: String
    let startTime: String
    let endTime: String
    let sentences: [YZSentenceDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case scenario
        case phase
        case startTime
        case endTime
        case sentences
    }

    init(
        id: String,
        scenario: String,
        phase: String,
        startTime: String,
        endTime: String,
        sentences: [YZSentenceDTO]
    ) {
        self.id = id
        self.scenario = scenario
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
        self.sentences = sentences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        scenario = try container.decode(String.self, forKey: .scenario)
        phase = try container.decode(String.self, forKey: .phase)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)

        if let lossySentences = try? container.decode(LossyArray<YZSentenceDTO>.self, forKey: .sentences) {
            sentences = lossySentences.elements
        } else {
            sentences = []
        }
    }
}

struct YZSessionFileDTO: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let totalSavedCount: Int
    let sessions: [YZSessionDTO]
    let droppedCount: Int

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case totalSavedCount
        case sessions
    }

    init(
        schemaVersion: Int,
        totalSavedCount: Int,
        sessions: [YZSessionDTO],
        droppedCount: Int = 0
    ) {
        self.schemaVersion = schemaVersion
        self.totalSavedCount = totalSavedCount
        self.sessions = sessions
        self.droppedCount = droppedCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1

        let lossySessions = try container.decodeIfPresent(LossyArray<YZSessionDTO>.self, forKey: .sessions)
            ?? LossyArray(elements: [], droppedCount: 0)
        sessions = lossySessions.elements
        droppedCount = lossySessions.droppedCount

        totalSavedCount = try container.decodeIfPresent(Int.self, forKey: .totalSavedCount)
            ?? lossySessions.elements.count
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(totalSavedCount, forKey: .totalSavedCount)
        try container.encode(sessions, forKey: .sessions)
    }
}