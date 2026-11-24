import AVFAudio
import Foundation

enum LocalSpeechAudioError: Error {
    case emptyAudio, invalidBuffer, formatChanged, timedOut, cancelled
}

// The speech callback may run off the main actor. Write each buffer before the
// callback returns, and serialize cancellation with file access using this lock.
final class LocalSpeechAudioWriter: @unchecked Sendable {
    private let lock = NSLock()
    private let url: URL
    private var file: AVAudioFile?
    private var frames: AVAudioFramePosition = 0
    private var resolved = false

    init(directory: URL = FileManager.default.temporaryDirectory) {
        url = directory.appendingPathComponent("ylct-speech-\(UUID().uuidString).caf")
    }

    func append(_ buffer: AVAudioBuffer) -> Result<Data, Error>? {
        lock.lock()
        defer { lock.unlock() }
        guard !resolved else { return nil }
        do {
            guard let pcm = buffer as? AVAudioPCMBuffer else { throw LocalSpeechAudioError.invalidBuffer }
            if pcm.frameLength == 0 {
                resolved = true
                file = nil // Close the file and finalize its header before reading.
                defer { try? FileManager.default.removeItem(at: url) }
                guard frames > 0 else { throw LocalSpeechAudioError.emptyAudio }
                return .success(try Data(contentsOf: url))
            }
            if file == nil {
                file = try AVAudioFile(forWriting: url, settings: pcm.format.settings,
                                       commonFormat: pcm.format.commonFormat, interleaved: pcm.format.isInterleaved)
            }
            guard let file, file.processingFormat == pcm.format else { throw LocalSpeechAudioError.formatChanged }
            try file.write(from: pcm)
            frames += AVAudioFramePosition(pcm.frameLength)
            return nil
        } catch {
            resolved = true
            file = nil
            try? FileManager.default.removeItem(at: url)
            return .failure(error)
        }
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        resolved = true
        file = nil
        try? FileManager.default.removeItem(at: url)
    }

    deinit { cancel() }
}

// Render locally first so the player can report an exact duration and an audio
// clock that keeps moving through punctuation and pauses, without word estimates.
@MainActor
final class LocalSpeechAudioRenderer: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let writer = LocalSpeechAudioWriter()
    private var utterance: AVSpeechUtterance?
    private var completion: ((Result<Data, Error>) -> Void)?
    private var timeout: Task<Void, Never>?

    func start(_ utterance: AVSpeechUtterance, completion: @escaping (Result<Data, Error>) -> Void) {
        self.utterance = utterance
        self.completion = completion
        synthesizer.delegate = self
        let writer = writer
        synthesizer.write(utterance) { [weak self, writer] buffer in
            guard let result = writer.append(buffer) else { return }
            Task { @MainActor [weak self] in self?.finish(result) }
        }
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(20)) } catch { return }
            self?.finish(.failure(LocalSpeechAudioError.timedOut))
        }
    }

    func cancel() {
        completion = nil
        timeout?.cancel()
        timeout = nil
        utterance = nil
        writer.cancel()
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func finish(_ result: Result<Data, Error>) {
        guard let completion else { return }
        cancel()
        completion(result)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.utterance === utterance else { return }
            self.finish(.failure(LocalSpeechAudioError.cancelled))
        }
    }
}
