import Foundation
import AVFAudio
import AVFoundation
import Speech
import Observation

enum SpeechListenState: String, Equatable {
    case idle
    case requestingPermission
    case listening
    case stopping
    case reconnecting
    case failed
    case blocked
}

struct SpeechFinalized: Equatable {
    let id: UUID
    let text: String
}

@MainActor
@Observable
final class SpeechService {
    private(set) var state: SpeechListenState = .idle
    private(set) var partialText: String = ""
    private(set) var errorMessage: String?
    private(set) var lastFinalized: SpeechFinalized?
    private(set) var reconnectAttempt: Int = 0

    let blockedMessage = "麦克风未授权：语音识别已停用，请继续用文字输入。"
    let speechBlockedMessage = "语音识别未授权：听写已停用，请继续用文字输入。"
    let failureMessage = "语音识别出错，请用文字输入。"
    let unsupportedMessage = "语音识别不可用，请用文字输入。"

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var sessionTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var permissionTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private var isUserStopped = false
    private var isFinalRestart = false
    private let silenceLimit: TimeInterval = 60
    private let sessionLimit: TimeInterval = 600
    private let maximumRetries = 2

    init() {
        observeAudioSession()
    }

    deinit {
        silenceTask?.cancel()
        sessionTask?.cancel()
        retryTask?.cancel()
        permissionTask?.cancel()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    var isActive: Bool {
        state == .requestingPermission || state == .listening || state == .reconnecting
    }

    var isBlocked: Bool {
        state == .blocked
    }

    func start() {
        guard state == .idle || state == .failed || state == .blocked else { return }
        isUserStopped = false
        isFinalRestart = false
        reconnectAttempt = 0
        errorMessage = nil
        state = .requestingPermission
        startPermissionWatchdog()

        requestMicrophonePermission { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.failAsBlocked(message: self.blockedMessage)
                return
            }
            self.requestSpeechPermission { [weak self] authorized in
                guard let self else { return }
                guard authorized else {
                    self.failAsBlocked(message: self.speechBlockedMessage)
                    return
                }
                guard let recognizer = self.recognizer, recognizer.isAvailable else {
                    self.fail(message: self.unsupportedMessage)
                    return
                }
                self.beginListening(isRetry: false)
            }
        }
    }

    private func startPermissionWatchdog() {
        permissionTask?.cancel()
        permissionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard let self, !Task.isCancelled, self.state == .requestingPermission else { return }
            self.fail(message: self.failureMessage)
        }
    }

    func stop() {
        let pending = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
        isUserStopped = true
        isFinalRestart = false
        retryTask?.cancel()
        retryTask = nil
        state = .stopping
        teardown()
        if !pending.isEmpty {
            lastFinalized = SpeechFinalized(id: UUID(), text: pending)
        }
        state = .idle
        partialText = ""
        reconnectAttempt = 0
        errorMessage = nil
    }

    func clearError() {
        guard state == .failed || state == .blocked else { return }
        errorMessage = nil
        clearPartialState()
        state = .idle
    }

    private func clearPartialState() {
        partialText = ""
        reconnectAttempt = 0
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in completion(granted) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in completion(granted) }
            }
        }
    }

    private func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in completion(status == .authorized) }
        }
    }

    private func beginListening(isRetry: Bool) {
        isFinalRestart = false
        guard !isUserStopped else { return }
        teardown(keepState: true)
        partialText = ""

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)
        } catch {
            fail(message: failureMessage)
            return
        }

        guard let recognizer = self.recognizer, recognizer.isAvailable else {
            fail(message: unsupportedMessage)
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            fail(message: failureMessage)
            return
        }

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        newRequest.taskHint = .dictation
        request = newRequest

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            newRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            fail(message: failureMessage)
            return
        }

        state = .listening
        if !isRetry {
            reconnectAttempt = 0
        }
        startSilenceTimer()
        if sessionTask == nil {
            startSessionTimer()
        }

        recognitionTask = recognizer.recognitionTask(with: newRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.handleRecognitionResult(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal
                    )
                }
                if let error {
                    self.handleRecognitionError()
                }
            }
        }
    }

    private func handleRecognitionResult(text: String, isFinal: Bool) {
        guard !isUserStopped else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        partialText = trimmed
        resetSilenceTimer()
        if !trimmed.isEmpty {
            reconnectAttempt = 0
        }
        guard isFinal, !trimmed.isEmpty else { return }
        lastFinalized = SpeechFinalized(id: UUID(), text: trimmed)
        partialText = ""
        restartAfterFinal()
    }

    private func restartAfterFinal() {
        guard !isUserStopped, state == .listening else { return }
        isFinalRestart = true
        teardown(keepState: true)
        retryTask?.cancel()
        retryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.2))
            guard let self, !Task.isCancelled, !self.isUserStopped else { return }
            self.beginListening(isRetry: true)
        }
    }

    private func handleRecognitionError() {
        guard !isUserStopped, !isFinalRestart else { return }
        guard state == .listening || state == .reconnecting else { return }
        scheduleReconnect(reasonMessage: failureMessage)
    }

    private func scheduleReconnect(reasonMessage: String?) {
        guard !isUserStopped else { return }
        guard reconnectAttempt < maximumRetries else {
            fail(message: reasonMessage ?? failureMessage)
            return
        }
        reconnectAttempt += 1
        state = .reconnecting
        teardown(keepState: true)
        let delay = reconnectAttempt == 1 ? 0.4 : 0.8
        retryTask?.cancel()
        retryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !Task.isCancelled, !self.isUserStopped else { return }
            self.beginListening(isRetry: true)
        }
    }

    private func startSilenceTimer() {
        silenceTask?.cancel()
        silenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(self?.silenceLimit ?? 60))
            guard let self, !Task.isCancelled, !self.isUserStopped else { return }
            guard self.state == .listening else { return }
            self.fail(message: self.failureMessage)
        }
    }

    private func resetSilenceTimer() {
        guard state == .listening else { return }
        startSilenceTimer()
    }

    private func startSessionTimer() {
        sessionTask?.cancel()
        sessionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(self?.sessionLimit ?? 600))
            guard let self, !Task.isCancelled, !self.isUserStopped else { return }
            guard self.isActive else { return }
            self.fail(message: self.failureMessage)
        }
    }

    private func failAsBlocked(message: String) {
        isUserStopped = true
        isFinalRestart = false
        teardown()
        state = .blocked
        errorMessage = message
        partialText = ""
    }

    private func fail(message: String) {
        isUserStopped = true
        isFinalRestart = false
        teardown()
        state = .failed
        errorMessage = message
        partialText = ""
    }

    private func teardown(keepState: Bool = false) {
        permissionTask?.cancel()
        permissionTask = nil
        silenceTask?.cancel()
        silenceTask = nil
        if !keepState {
            sessionTask?.cancel()
            sessionTask = nil
            retryTask?.cancel()
            retryTask = nil
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    self?.handleInterruption(notification)
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

    private func handleInterruption(_ notification: Notification) {
        guard
            let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: raw)
        else {
            return
        }
        if type == .began {
            stopSilently()
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: raw)
        else {
            return
        }
        guard reason == .oldDeviceUnavailable || reason == .newDeviceAvailable else { return }
        stopSilently()
    }

    private func stopSilently() {
        guard isActive || state == .stopping else { return }
        isUserStopped = true
        isFinalRestart = false
        teardown()
        state = .idle
        partialText = ""
        reconnectAttempt = 0
    }
}
