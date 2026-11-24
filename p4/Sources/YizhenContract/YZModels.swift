import Foundation

/// P1 YZModels 的占位契约。仅声明领域模型，不参与落盘编码。
public enum YZSpeaker: Sendable, Equatable, Hashable {
    case me
    case other
    case unknown(String?)
}

public struct YZSentence: Sendable, Equatable, Hashable {
    public let speaker: YZSpeaker
    public let text: String

    public init(speaker: YZSpeaker, text: String) {
        self.speaker = speaker
        self.text = text
    }
}

public struct YZSession: Sendable, Equatable, Identifiable {
    public let id: String
    public let scenario: String
    public let phase: String
    public let startTime: Date
    public let endTime: Date
    public let sentences: [YZSentence]

    public init(
        id: String,
        scenario: String,
        phase: String,
        startTime: Date,
        endTime: Date,
        sentences: [YZSentence]
    ) {
        self.id = id
        self.scenario = scenario
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
        self.sentences = sentences
    }
}

public struct YZSessionDraft: Sendable, Equatable {
    public let id: String?
    public let scenario: String
    public let phase: String
    public let startTime: Date
    public let endTime: Date
    public let sentences: [YZSentence]

    public init(
        id: String?,
        scenario: String,
        phase: String,
        startTime: Date,
        endTime: Date,
        sentences: [YZSentence]
    ) {
        self.id = id
        self.scenario = scenario
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
        self.sentences = sentences
    }
}