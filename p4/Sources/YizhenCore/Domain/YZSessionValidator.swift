import Foundation

/// Domain 层校验输入，避免 Domain 依赖 P1 的 YZSessionDraft。
public struct YZSessionValidationInput: Sendable, Equatable {
    public let id: String?
    public let scenario: String
    public let phase: String
    public let startTime: Date
    public let endTime: Date
    public let sentences: [YZStoredSentence]

    public init(
        id: String?,
        scenario: String,
        phase: String,
        startTime: Date,
        endTime: Date,
        sentences: [YZStoredSentence]
    ) {
        self.id = id
        self.scenario = scenario
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
        self.sentences = sentences
    }
}

public struct YZSessionValidator: Sendable {
    public static let maxFieldCharacters = 50

    public init() {}

    public func normalize(
        _ input: YZSessionValidationInput,
        generatedID: YZSessionID
    ) -> Result<YZStoredSession, YZSessionInvalidField> {
        let scenario = input.scenario.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scenario.isEmpty, scenario.count <= Self.maxFieldCharacters else {
            return .failure(.scenario)
        }

        let phase = input.phase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phase.isEmpty, phase.count <= Self.maxFieldCharacters else {
            return .failure(.phase)
        }

        let identifier: YZSessionID
        if let rawIdentifier = input.id {
            let trimmedIdentifier = rawIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedIdentifier.isEmpty else {
                return .failure(.emptyIdentifier)
            }
            identifier = YZSessionID(trimmedIdentifier)
        } else {
            guard !generatedID.rawValue.isEmpty else {
                return .failure(.emptyIdentifier)
            }
            identifier = generatedID
        }

        let startTime = Self.flooredToSecond(input.startTime)
        let endTime = Self.flooredToSecond(input.endTime)
        guard endTime >= startTime else {
            return .failure(.timeRange)
        }

        var sentences: [YZStoredSentence] = []
        sentences.reserveCapacity(input.sentences.count)
        for sentence in input.sentences {
            let text = sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            sentences.append(YZStoredSentence(speaker: sentence.speaker, text: text))
        }

        return .success(
            YZStoredSession(
                id: identifier,
                scenario: scenario,
                phase: phase,
                startTime: startTime,
                endTime: endTime,
                sentences: sentences
            )
        )
    }

    public func estimatedEncodedBytes(_ session: YZStoredSession) -> Int {
        var total = 128
        total += session.id.rawValue.utf8.count
        total += session.scenario.utf8.count
        total += session.phase.utf8.count
        for sentence in session.sentences {
            total += 32
            total += sentence.speaker.rawValue.utf8.count
            total += sentence.text.utf8.count
        }
        return total
    }

    public static func flooredToSecond(_ date: Date) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down))
    }
}