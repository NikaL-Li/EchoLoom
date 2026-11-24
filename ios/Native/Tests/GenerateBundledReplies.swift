import Foundation

// Maintainer-only utility. Uses the app's actual MiMo request and WAV validation.
// This file is not included in the app target and never runs on a user's device.
@main
struct GenerateBundledReplies {
    static func main() async throws {
        let directory = URL(fileURLWithPath: "Sources/Resources/Presets", isDirectory: true)
        for text in BundledReplyAudio.files.keys.sorted() {
            for voice in PhraseVoice.allCases {
                let resource = BundledReplyAudio.resourceName(text: text, voice: voice)!
                let url = directory.appendingPathComponent(resource + ".wav")
                if FileManager.default.fileExists(atPath: url.path) {
                    try CustomPhraseStore.validateAudio(Data(contentsOf: url))
                    print("VERIFIED \(resource)")
                    continue
                }
                print("GENERATING \(resource)")
                let data = try await MiMoPhraseAudio.fetch(text: text, voice: voice)
                try data.write(to: url, options: .atomic)
                print("SAVED \(resource): \(data.count) bytes")
            }
        }
    }
}
