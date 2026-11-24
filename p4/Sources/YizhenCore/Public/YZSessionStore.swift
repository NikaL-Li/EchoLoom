import Foundation
import YizhenContract

/// 唯一对外实现类型。actor 隔离保证全部变更串行。
public actor YZSessionStore: YZSessionStoring, YZSessionStatisticsProviding, YZSessionExporting {
    private let environment: YZSessionStoreEnvironment
    private let codec: YZSessionFileCodec
    private let repository: YZSessionFileRepository
    private let validator: YZSessionValidator
    private let retention: YZSessionRetentionPolicy
    private let calculator: YZSessionStatisticsCalculator
    private let composer: YZSessionTextComposer
    private let mapper: YZSessionMapper
    private let logger: any YZSessionStoreLogger
    private var current: YZSessionSnapshot?

    public init(
        environment: YZSessionStoreEnvironment = .production,
        retention: YZSessionRetentionPolicy = .default,
        logger: (any YZSessionStoreLogger)? = nil
    ) {
        self.environment = environment
        let codec = YZSessionFileCodec()
        self.codec = codec
        self.repository = YZSessionFileRepository(fileSystem: environment.fileSystem, codec: codec)
        self.validator = YZSessionValidator()
        self.retention = retention
        self.calculator = YZSessionStatisticsCalculator()
        self.composer = YZSessionTextComposer()
        self.mapper = YZSessionMapper()
        self.logger = logger ?? environment.logger
        self.current = nil
    }

    // MARK: - 读取

    public func sessions() async -> [YZSession] {
        let snapshot = loadedSnapshot()
        return snapshot.sortedDescending().map { mapper.toPublic($0) }
    }

    // MARK: - 保存

    public func save(_ session: YZSessionDraft) async -> YZSessionSaveResult {
        let started = Date()
        let snapshot = loadedSnapshot()
        let generatedID = YZSessionID(UUID().uuidString)
        let input = mapper.validationInput(session)

        let normalized: YZStoredSession
        switch validator.normalize(input, generatedID: generatedID) {
        case .success(let value):
            normalized = value
        case .failure(let field):
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.invalidField.rawValue,
                    operation: .save,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .invalid(field)
        }

        do {
            let sessionBytes = try repository.encodedSize(of: normalized)
            if sessionBytes > YZSessionSnapshot.maxSessionBytes {
                logger.log(
                    YZSessionLogEvent(
                        errorCode: YZSessionErrorCode.invalidField.rawValue,
                        operation: .save,
                        durationMs: elapsedMilliseconds(since: started)
                    )
                )
                return .invalid(.sessionTooLarge)
            }
        } catch {
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.writeFailed.rawValue,
                    operation: .save,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .failed(.writeFailed(underlyingCode: describe(error)))
        }

        let isUpdate = snapshot.sessions.contains { $0.id == normalized.id }
        var sessions = snapshot.sessions
        if isUpdate {
            sessions.removeAll { $0.id == normalized.id }
        }
        sessions.append(normalized)

        var candidate = YZSessionSnapshot(
            sessions: sessions,
            totalSavedCount: isUpdate ? snapshot.totalSavedCount : snapshot.totalSavedCount + 1
        )

        _ = retention.trim(&candidate.sessions)
        candidate = YZSessionSnapshot(
            sessions: candidate.sessions,
            totalSavedCount: candidate.totalSavedCount
        )

        let candidateTotal = candidate.totalSavedCount
        let sizeCodec = codec
        _ = retention.trimForSize(&candidate.sessions, maxBytes: retention.maxFileBytes) { sessions in
            let probe = YZSessionSnapshot(sessions: sessions, totalSavedCount: candidateTotal)
            return (try? sizeCodec.encode(probe).count) ?? Int.max
        }
        candidate = YZSessionSnapshot(
            sessions: candidate.sessions,
            totalSavedCount: candidate.totalSavedCount
        )

        do {
            _ = try repository.save(candidate)
            current = candidate
            logger.log(
                YZSessionLogEvent(
                    operation: .save,
                    count: candidate.sessions.count,
                    durationMs: elapsedMilliseconds(since: started),
                    schemaVersion: YZSessionFileCodec.currentSchemaVersion
                )
            )
            return .saved(normalized.id)
        } catch {
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.writeFailed.rawValue,
                    operation: .save,
                    count: candidate.sessions.count,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .failed(.writeFailed(underlyingCode: describe(error)))
        }
    }

    // MARK: - 删除与清空

    public func delete(id: YZSessionID) async -> YZSessionDeleteResult {
        let started = Date()
        let snapshot = loadedSnapshot()
        guard snapshot.sessions.contains(where: { $0.id == id }) else {
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.notFound.rawValue,
                    operation: .delete,
                    count: 0,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .notFound
        }

        var sessions = snapshot.sessions
        sessions.removeAll { $0.id == id }
        let candidate = YZSessionSnapshot(
            sessions: sessions,
            totalSavedCount: snapshot.totalSavedCount
        )

        do {
            _ = try repository.save(candidate)
            current = candidate
            logger.log(
                YZSessionLogEvent(
                    operation: .delete,
                    count: candidate.sessions.count,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .deleted
        } catch {
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.writeFailed.rawValue,
                    operation: .delete,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .failed(.writeFailed(underlyingCode: describe(error)))
        }
    }

    public func clearAll() async -> YZSessionClearResult {
        let started = Date()
        _ = loadedSnapshot()

        let candidate = YZSessionSnapshot.empty
        do {
            _ = try repository.save(candidate)
            current = candidate
            logger.log(
                YZSessionLogEvent(
                    operation: .clear,
                    count: 0,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .cleared
        } catch {
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.writeFailed.rawValue,
                    operation: .clear,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .failed(.writeFailed(underlyingCode: describe(error)))
        }
    }

    // MARK: - 统计

    public func statistics() async -> YZSessionStatistics {
        let started = Date()
        let snapshot = loadedSnapshot()
        let calendar = environment.calendar.currentCalendar()
        let now = environment.clock.now()
        let result = calculator.calculate(snapshot: snapshot, now: now, calendar: calendar)
        logger.log(
            YZSessionLogEvent(
                operation: .statistics,
                count: result.todayCount,
                durationMs: elapsedMilliseconds(since: started)
            )
        )
        return result
    }

    public func todayCount() async -> Int {
        let result = await statistics()
        return result.todayCount
    }

    // MARK: - 导出

    public func exportSession(id: YZSessionID) async -> YZExportResult {
        let started = Date()
        let snapshot = loadedSnapshot()
        guard let session = snapshot.sessions.first(where: { $0.id == id }) else {
            logger.log(
                YZSessionLogEvent(
                    errorCode: YZSessionErrorCode.notFound.rawValue,
                    operation: .export,
                    count: 0,
                    durationMs: elapsedMilliseconds(since: started)
                )
            )
            return .notFound
        }

        let exportTime = environment.clock.now()
        let timeZone = environment.calendar.currentCalendar().timeZone
        let text = composer.composeSingle(
            session,
            display: resolvedDisplayNames(),
            timeZone: timeZone,
            exportTime: exportTime
        )
        let fileName = composer.suggestedFileName(kind: .single, at: exportTime, timeZone: timeZone)

        logger.log(
            YZSessionLogEvent(
                operation: .export,
                count: 1,
                durationMs: elapsedMilliseconds(since: started)
            )
        )
        return .success(YZExportDocument(text: text, suggestedFileName: fileName))
    }

    public func exportAll() async -> YZExportDocument {
        let started = Date()
        let snapshot = loadedSnapshot()
        let exportTime = environment.clock.now()
        let timeZone = environment.calendar.currentCalendar().timeZone
        let text = composer.composeAll(
            snapshot.sortedAscending(),
            display: resolvedDisplayNames(),
            timeZone: timeZone,
            exportTime: exportTime
        )
        let fileName = composer.suggestedFileName(kind: .all, at: exportTime, timeZone: timeZone)

        logger.log(
            YZSessionLogEvent(
                operation: .export,
                count: snapshot.sessions.count,
                durationMs: elapsedMilliseconds(since: started)
            )
        )
        return YZExportDocument(text: text, suggestedFileName: fileName)
    }

    // MARK: - 内部

    private func loadedSnapshot() -> YZSessionSnapshot {
        if let snapshot = current {
            return snapshot
        }

        switch repository.load() {
        case .loaded(let snapshot, let droppedCount):
            var sessions = snapshot.sessions
            if sessions.count > retention.maxRetained {
                _ = retention.trim(&sessions)
            }
            let normalized = YZSessionSnapshot(
                sessions: sessions,
                totalSavedCount: snapshot.totalSavedCount
            )
            current = normalized

            if droppedCount > 0 {
                logger.log(
                    YZSessionLogEvent(
                        errorCode: YZSessionErrorCode.decodeFailed.rawValue,
                        operation: .load,
                        count: droppedCount
                    )
                )
            }
            return normalized

        case .empty(let reason):
            current = YZSessionSnapshot.empty
            if reason == .corrupted {
                logger.log(
                    YZSessionLogEvent(
                        errorCode: YZSessionErrorCode.decodeFailed.rawValue,
                        operation: .load,
                        count: 0
                    )
                )
            }
            return YZSessionSnapshot.empty
        }
    }

    private func resolvedDisplayNames() -> any YZSessionDisplayNameProviding {
        if let displayNames = environment.displayNames {
            return displayNames
        }
        return YZStableDisplayNameProvider()
    }

    private func elapsedMilliseconds(since start: Date) -> Int {
        max(0, Int(Date().timeIntervalSince(start) * 1000))
    }

    private func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return "\(nsError.domain):\(nsError.code)"
    }
}