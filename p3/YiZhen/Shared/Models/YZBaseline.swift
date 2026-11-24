import Foundation

enum YZBaseline: String, CaseIterable, Equatable {
    case threeMessages
    case empty

    static var current: YZBaseline {
        resolve(fromEnvironment: ProcessInfo.processInfo.environment, arguments: ProcessInfo.processInfo.arguments)
    }

    static func resolve(fromEnvironment environment: [String: String], arguments: [String]) -> YZBaseline {
        var raw = environment["YZ_BASELINE"]
        if let index = arguments.firstIndex(of: "-YZ_BASELINE"), arguments.indices.contains(index + 1) {
            raw = arguments[index + 1]
        }
        guard let raw else { return .threeMessages }
        return YZBaseline(rawValue: raw) ?? .threeMessages
    }
}
enum YZPhraseBaseline: String, CaseIterable, Equatable {
    case six
    case empty

    static var current: YZPhraseBaseline {
        guard let raw = ProcessInfo.processInfo.environment["YZ_PHRASE_BASELINE"] else {
            return .six
        }
        return YZPhraseBaseline(rawValue: raw) ?? .six
    }
}