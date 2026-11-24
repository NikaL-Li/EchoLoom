import Foundation

public enum YZSessionInvalidField: String, Error, Sendable, Equatable, CaseIterable {
    case scenario
    case phase
    case timeRange
    case sessionTooLarge
    case emptyIdentifier
}