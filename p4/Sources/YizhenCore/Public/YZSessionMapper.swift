import Foundation
import YizhenContract

/// P1 模型与内部模型的双向转换。只做类型转换，不做校验、编码或文本拼接。
public struct YZSessionMapper: Sendable {
    public init() {}

    public func validationInput(_ draft: YZSessionDraft) -> YZSessionValidationInput {
        YZSessionValidationInput(
            id: draft.id,
            scenario: draft.scenario,
            phase: draft.phase,
            startTime: draft.startTime,
            endTime: draft.endTime,
            sentences: draft.sentences.map { toStoredSentence($0) }
        )
    }

    public func toStored(_ draft: YZSessionDraft, id: YZSessionID) -> YZStoredSession {
        YZStoredSession(
            id: id,
            scenario: draft.scenario,
            phase: draft.phase,
            startTime: draft.startTime,
            endTime: draft.endTime,
            sentences: draft.sentences.map { toStoredSentence($0) }
        )
    }

    public func toStoredSentence(_ sentence: YZSentence) -> YZStoredSentence {
        YZStoredSentence(speaker: toStoredSpeaker(sentence.speaker), text: sentence.text)
    }

    public func toStoredSpeaker(_ speaker: YZSpeaker) -> YZStoredSpeaker {
        switch speaker {
        case .me:
            return .me
        case .other:
            return .other
        case .unknown(let rawValue):
            return .unknown(rawValue)
        }
    }

    public func toPublic(_ session: YZStoredSession) -> YZSession {
        YZSession(
            id: session.id.rawValue,
            scenario: session.scenario,
            phase: session.phase,
            startTime: session.startTime,
            endTime: session.endTime,
            sentences: session.sentences.map { toPublicSentence($0) }
        )
    }

    public func toPublicSentence(_ sentence: YZStoredSentence) -> YZSentence {
        YZSentence(speaker: toPublicSpeaker(sentence.speaker), text: sentence.text)
    }

    public func toPublicSpeaker(_ speaker: YZStoredSpeaker) -> YZSpeaker {
        switch speaker {
        case .me:
            return .me
        case .other:
            return .other
        case .unknown(let rawValue):
            return .unknown(rawValue)
        }
    }
}