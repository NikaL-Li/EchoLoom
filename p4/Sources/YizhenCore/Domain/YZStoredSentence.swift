import Foundation

public struct YZStoredSentence: Sendable, Equatable, Hashable {
    public let speaker: YZStoredSpeaker
    public let text: String

    public init(speaker: YZStoredSpeaker, text: String) {
        self.speaker = speaker
        self.text = text
    }
}