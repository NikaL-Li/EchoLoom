import Foundation

public enum YZSessionSaveResult: Sendable, Equatable {
    case saved(YZSessionID)
    case invalid(YZSessionInvalidField)
    case failed(YZSessionStoreError)
}

public enum YZSessionDeleteResult: Sendable, Equatable {
    case deleted
    case notFound
    case failed(YZSessionStoreError)
}

public enum YZSessionClearResult: Sendable, Equatable {
    case cleared
    case failed(YZSessionStoreError)
}