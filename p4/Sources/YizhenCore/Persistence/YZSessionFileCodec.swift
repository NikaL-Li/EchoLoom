import Foundation

public enum YZSessionDecodeOutcome: Sendable, Equatable {
    case decoded(snapshot: YZSessionSnapshot, droppedCount: Int, schemaVersion: Int)
    case corrupted
}

/// 严格编码、宽松解码。所有落盘字段名与时间格式集中在此处。
public struct YZSessionFileCodec: Sendable {
    public static let currentSchemaVersion = 1

    private let timeZone: TimeZone

    public init(timeZone: TimeZone = .current) {
        self.timeZone = timeZone
    }

    public func encode(_ snapshot: YZSessionSnapshot) throws -> Data {
        let dto = YZSessionFileDTO(
            schemaVersion: Self.currentSchemaVersion,
            totalSavedCount: snapshot.totalSavedCount,
            sessions: snapshot.sessions.map(makeDTO)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return try encoder.encode(dto)
    }

    public func decode(_ data: Data) -> YZSessionDecodeOutcome {
        guard !data.isEmpty else { return .corrupted }
        guard let dto = try? JSONDecoder().decode(YZSessionFileDTO.self, from: data) else {
            return .corrupted
        }

        var droppedCount = dto.droppedCount
        var storedSessions: [YZStoredSession] = []
        storedSessions.reserveCapacity(dto.sessions.count)

        for sessionDTO in dto.sessions {
            if let session = makeStored(sessionDTO) {
                storedSessions.append(session)
            } else {
                droppedCount += 1
            }
        }

        if storedSessions.count > YZSessionSnapshot.maxRetainedSessions {
            droppedCount += storedSessions.count - YZSessionSnapshot.maxRetainedSessions
            storedSessions = Array(storedSessions.prefix(YZSessionSnapshot.maxRetainedSessions))
        }

        let snapshot = YZSessionSnapshot(
            sessions: storedSessions,
            totalSavedCount: dto.totalSavedCount
        )
        let schemaVersion = max(1, dto.schemaVersion)
        return .decoded(snapshot: snapshot, droppedCount: droppedCount, schemaVersion: schemaVersion)
    }

    public func encodedSize(of session: YZStoredSession) throws -> Int {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return try encoder.encode(makeDTO(session)).count
    }

    private func makeDTO(_ session: YZStoredSession) -> YZSessionDTO {
        YZSessionDTO(
            id: session.id.rawValue,
            scenario: session.scenario,
            phase: session.phase,
            startTime: format(session.startTime),
            endTime: format(session.endTime),
            sentences: session.sentences.map {
                YZSentenceDTO(speaker: $0.speaker.rawValue, text: $0.text)
            }
        )
    }

    private func makeStored(_ dto: YZSessionDTO) -> YZStoredSession? {
        let identifier = dto.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !identifier.isEmpty else { return nil }

        var scenario = dto.scenario.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scenario.isEmpty else { return nil }
        if scenario.count > YZSessionValidator.maxFieldCharacters {
            scenario = String(scenario.prefix(YZSessionValidator.maxFieldCharacters))
        }

        var phase = dto.phase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phase.isEmpty else { return nil }
        if phase.count > YZSessionValidator.maxFieldCharacters {
            phase = String(phase.prefix(YZSessionValidator.maxFieldCharacters))
        }

        guard let startTime = parseDate(dto.startTime),
              let endTime = parseDate(dto.endTime),
              endTime >= startTime else {
            return nil
        }

        var sentences: [YZStoredSentence] = []
        sentences.reserveCapacity(dto.sentences.count)
        for sentenceDTO in dto.sentences {
            let text = sentenceDTO.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            sentences.append(
                YZStoredSentence(
                    speaker: makeSpeaker(sentenceDTO.speaker),
                    text: text
                )
            )
        }

        return YZStoredSession(
            id: YZSessionID(identifier),
            scenario: scenario,
            phase: phase,
            startTime: YZSessionValidator.flooredToSecond(startTime),
            endTime: YZSessionValidator.flooredToSecond(endTime),
            sentences: sentences
        )
    }

    private func makeSpeaker(_ rawValue: String) -> YZStoredSpeaker {
        switch rawValue {
        case "me":
            return .me
        case "other":
            return .other
        default:
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return .unknown(trimmed.isEmpty ? nil : rawValue)
        }
    }

    private func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = timeZone
        return formatter.string(from: YZSessionValidator.flooredToSecond(date))
    }

    private func parseDate(_ rawValue: String) -> Date? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let internetFormatter = ISO8601DateFormatter()
        internetFormatter.formatOptions = [.withInternetDateTime]
        if let date = internetFormatter.date(from: trimmed) {
            return date
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: trimmed) {
            return date
        }

        let localFormatter = DateFormatter()
        localFormatter.locale = Locale(identifier: "en_US_POSIX")
        localFormatter.timeZone = timeZone
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return localFormatter.date(from: trimmed)
    }
}