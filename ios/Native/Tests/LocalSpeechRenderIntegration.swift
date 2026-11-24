import AVFAudio
import Foundation

// Optional host integration check: synthesize to memory, never play sound.
@main
struct LocalSpeechRenderIntegration {
    @MainActor static func main() async throws {
        let utterance = AVSpeechUtterance(string: "您好。请在东门等我，我正在确认地址。谢谢您的理解。")
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.48
        guard utterance.voice != nil else { throw LocalSpeechAudioError.emptyAudio }
        let renderer = LocalSpeechAudioRenderer()
        let started = ProcessInfo.processInfo.systemUptime
        let result: Result<Data, Error> = await withCheckedContinuation { continuation in
            renderer.start(utterance) { continuation.resume(returning: $0) }
        }
        withExtendedLifetime(renderer) {}
        guard case .success(let data) = result else {
            print("System voice rendering unavailable: \(result)")
            exit(1)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ylct-render-integration-\(UUID()).caf")
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url)
        let file = try AVAudioFile(forReading: url)
        let duration = Double(file.length) / file.processingFormat.sampleRate
        precondition(duration > 1 && data.count > 1000)
        print("PASS: real local speech rendered to playable audio with duration \(duration)s")
        print("Render preparation: \(ProcessInfo.processInfo.systemUptime - started)s; no audio played.")
    }
}
