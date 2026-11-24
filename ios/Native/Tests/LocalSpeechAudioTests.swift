import AVFAudio
import Foundation

@main
struct LocalSpeechAudioTests {
    static var checks = 0
    static func check(_ condition: Bool, _ message: String) {
        precondition(condition, message)
        checks += 1
        print("PASS: \(message)")
    }
    static func buffer(_ frames: AVAudioFrameCount, amplitude: Float = 0, sampleRate: Double = 24000) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: max(frames, 1))!
        pcm.frameLength = frames
        if frames > 0 { pcm.floatChannelData![0].initialize(repeating: amplitude, count: Int(frames)) }
        return pcm
    }

    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ylct-render-checks-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        func files() throws -> [String] { try FileManager.default.contentsOfDirectory(atPath: directory.path) }
        let writer = LocalSpeechAudioWriter(directory: directory)
        check(writer.append(buffer(12000, amplitude: 0.25)) == nil, "partial synthesis does not start audible playback")
        check(writer.append(buffer(18000)) == nil, "punctuation silence is retained in the audio")
        check(writer.append(buffer(12000, amplitude: 0.5)) == nil, "multiple speech buffers append in order")
        let data = try writer.append(buffer(0))!.get()
        check(try files().isEmpty, "completed synthesis removes its temporary file")
        check(writer.append(buffer(24000)) == nil, "late buffers cannot append after completion")
        check(writer.append(buffer(0)) == nil, "completion is delivered only once")
        let saved = directory.appendingPathComponent("verify.caf")
        try data.write(to: saved)
        let audio = try AVAudioFile(forReading: saved)
        check(audio.length == 42000, "rendered file contains all speech and silent frames")
        let duration = Double(audio.length) / audio.processingFormat.sampleRate
        check(abs(duration - 1.75) < 0.000001, "exact audio duration includes the full spoken pause")
        let decoded = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length))!
        try audio.read(into: decoded)
        check(decoded.floatChannelData![0][0] == 0.25, "first speech segment retains its samples")
        check(decoded.floatChannelData![0][12000] == 0 && decoded.floatChannelData![0][29999] == 0, "the entire silent interval survives encoding")
        check(decoded.floatChannelData![0][30000] == 0.5, "speech after the pause retains its samples")
        try FileManager.default.removeItem(at: saved)

        let clock = PlaybackProgressClock()
        let snapshot = PlaybackSnapshot(id: UUID(), phase: .playing, duration: duration)
        var position = 0.5
        clock.start(snapshot, audioPosition: { position })
        var samples: [Double] = []
        for frame in 0..<45 {
            position = 0.5 + Double(frame) / 60
            samples.append(clock.sample(fallback: snapshot).progress)
        }
        check(Set(samples).count == 45, "progress advances on every frame throughout punctuation silence")
        check(zip(samples, samples.dropFirst()).allSatisfy { abs(($1 - $0) - 1 / (60 * duration)) < 0.000001 }, "silent and spoken frames use the same continuous rate")
        position = 1.1
        let stopped = clock.finish(.stopped, fallback: snapshot)
        check(stopped.progress < 1 && stopped.phase == .stopped, "stopping inside a pause never claims completion")

        let cancelled = LocalSpeechAudioWriter(directory: directory)
        _ = cancelled.append(buffer(12000))
        check(try files().count == 1, "partial render owns one isolated temporary file")
        cancelled.cancel()
        check(try files().isEmpty, "cancelling preparation closes and removes partial audio")
        check(cancelled.append(buffer(0)) == nil && cancelled.append(buffer(12000)) == nil, "late callbacks after cancellation cannot restart playback")
        cancelled.cancel()
        check(try files().isEmpty, "cancellation is idempotent")

        let empty = LocalSpeechAudioWriter(directory: directory)
        if case .failure? = empty.append(buffer(0)) { check(true, "empty speech fails instead of playing zero duration") }
        else { check(false, "empty speech must fail") }
        let changed = LocalSpeechAudioWriter(directory: directory)
        _ = changed.append(buffer(100))
        if case .failure? = changed.append(buffer(100, sampleRate: 48000)) { check(true, "changing audio formats fails without corrupting a file") }
        else { check(false, "format changes must fail") }
        check(try files().isEmpty, "failed render removes partial audio")
        check(changed.append(buffer(0)) == nil, "failed rendering cannot later publish success")
        print("Final total: \(checks) local speech audio checks passed.")
    }
}
