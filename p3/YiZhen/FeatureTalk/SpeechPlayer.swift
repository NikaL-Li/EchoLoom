import Foundation
import AVFoundation
import Observation

struct SpeechPlaybackResult: Equatable {
    let id: UUID
    let messageID: String?
    let success: Bool
}

@MainActor
@Observable
final class SpeechPlayer: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var lastResult: SpeechPlaybackResult?

    private let synthesizer = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?
    private var activeMessageID: String?
    private var timeoutTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private var generation = 0

    override init() {
        super.init()
        synthesizer.delegate = self
        observeAudioSession()
    }

    deinit {
        timeoutTask?.cancel()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    func speak(_ rawText: String, messageID: String? = nil) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            emitResult(messageID: messageID, success: false)
            return
        }

        generation += 1
        let currentGeneration = generation
        timeoutTask?.cancel()
        activeUtterance = nil
        activeMessageID = messageID
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        guard let voice = AVSpeechSynthesisVoice(language: "zh-CN") else {
            activeMessageID = nil
            emitResult(messageID: messageID, success: false)
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            activeMessageID = nil
            emitResult(messageID: messageID, success: false)
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        activeUtterance = utterance
        synthesizer.speak(utterance)
        startTimeout(seconds: timeoutSeconds(for: text), generation: currentGeneration)
    }

    func stop() {
        generation += 1
        timeoutTask?.cancel()
        timeoutTask = nil
        let wasActive = activeUtterance != nil || synthesizer.isSpeaking
        activeUtterance = nil
        activeMessageID = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if wasActive {
            deactivateSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.handleFinish(utterance: utterance)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.handleCancel(utterance: utterance)
        }
    }

    private func handleFinish(utterance: AVSpeechUtterance) {
        guard utterance === activeUtterance else { return }
        let messageID = activeMessageID
        activeUtterance = nil
        activeMessageID = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        emitResult(messageID: messageID, success: true)
        deactivateSession()
    }

    private func handleCancel(utterance: AVSpeechUtterance) {
        guard utterance === activeUtterance else { return }
        activeUtterance = nil
        activeMessageID = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        deactivateSession()
    }

    private func startTimeout(seconds: TimeInterval, generation: Int) {
        timeoutTask?.cancel()
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, self.generation == generation else { return }
            let messageID = self.activeMessageID
            self.activeUtterance = nil
            self.activeMessageID = nil
            self.synthesizer.stopSpeaking(at: .immediate)
            self.emitResult(messageID: messageID, success: false)
            self.deactivateSession()
        }
    }

    private func timeoutSeconds(for text: String) -> TimeInterval {
        min(60, max(15, Double(text.count) * 0.32))
    }

    private func emitResult(messageID: String?, success: Bool) {
        lastResult = SpeechPlaybackResult(
            id: UUID(),
            messageID: messageID,
            success: success
        )
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.stop()
                }
            }
        )
        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    self?.handleRouteChange(notification)
                }
            }
        )
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: raw)
        else {
            return
        }
        if reason == .oldDeviceUnavailable || reason == .newDeviceAvailable {
            stop()
        }
    }
}