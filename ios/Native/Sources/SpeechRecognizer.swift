import AVFAudio
import Foundation
import Speech
import Combine
import UIKit

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var authorized = false
    @Published var microphoneAuthorized = false
    @Published var speechAuthorized = false
    @Published var permissionText = "未检查"
    @Published var errorText: String?
    private lazy var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var tapInstalled = false
    private var ownsSession = false
    private var generation = 0
    private var segmentID: UUID?
    var onEnd: ((UUID, String, Bool) -> Void)?

    var needsSettings: Bool {
        AVAudioApplication.shared.recordPermission == .denied || SFSpeechRecognizer.authorizationStatus() == .denied || SFSpeechRecognizer.authorizationStatus() == .restricted
    }
    func refreshStatus() {
        microphoneAuthorized = AVAudioApplication.shared.recordPermission == .granted
        speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        authorized = microphoneAuthorized && speechAuthorized
        permissionText = authorized ? "已授权" : "未授权"
    }
    func requestAuthorization() async {
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            _ = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
        }
        guard !Task.isCancelled else { return }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else { refreshStatus(); return }
        if AVAudioApplication.shared.recordPermission == .undetermined { _ = await AVAudioApplication.requestRecordPermission() }
        refreshStatus()
    }
    func toggleListening() { if isRecording { stop() } else { start() } }
    func start() {
        refreshStatus()
        guard authorized else { errorText = "请在「我的 → 权限管理」中开启麦克风和语音识别。"; return }
        guard let recognizer, recognizer.isAvailable else { errorText = "当前语音识别不可用，请检查网络，或改用大字牌。"; return }
        stop()
        let currentGeneration = generation
        transcript = ""
        errorText = nil
        segmentID = UUID()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            ownsSession = true
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
            self.request = request
            let engine = audioEngine ?? AVAudioEngine()
            audioEngine = engine
            let input = engine.inputNode
            let format = input.inputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                errorText = "麦克风暂时被占用，请结束其他录音后重试。"
                stop()
                return
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            tapInstalled = true
            engine.prepare()
            try engine.start()
            isRecording = true
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.generation == currentGeneration else { return }
                    if let result { self.transcript = result.bestTranscription.formattedString }
                    if error != nil || (result?.isFinal ?? false) {
                        if error != nil { self.errorText = "转写已暂停，请靠近对方后重试；也可以请对方打字。" }
                        self.finish(mayContinue: error == nil && result?.isFinal == true)
                    }
                }
            }
        } catch {
            errorText = "麦克风启动失败，请稍后重试。"
            stop()
        }
    }
    func stop() { finish(mayContinue: false) }
    private func finish(mayContinue: Bool) {
        let endedSegment = segmentID
        segmentID = nil
        generation += 1
        if audioEngine?.isRunning == true { audioEngine?.stop() }
        if tapInstalled { audioEngine?.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
        // A view disappearing must not deactivate audio that belongs to call playback.
        if ownsSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            ownsSession = false
        }
        if let endedSegment { onEnd?(endedSegment, transcript, mayContinue) }
    }
}


@MainActor
final class FaceToFaceConversation: ObservableObject {
    var hapticsEnabled = true
    @Published var log = ConversationLog()
    @Published var isFaceToFace = false
    @Published var partnerDraft = ""
    @Published private(set) var listening = ConversationListeningGate()
    @Published private(set) var requesting = false
    @Published private(set) var notice = ""
    private let speech: SpeechRecognizer
    private let playback: CallInjectionManager
    private var permissionTask: Task<Void, Never>?
    private var restartTask: Task<Void, Never>?
    private var requestGeneration = 0
    private var subscriptions = Set<AnyCancellable>()
    private var scope: DialogueScope = .home
    private var savedScopes: [DialogueScope: (ConversationLog, String)] = [:]

    init(speech: SpeechRecognizer, playback: CallInjectionManager) {
        self.speech = speech
        self.playback = playback
        speech.onEnd = { [weak self] id, text, mayContinue in
            guard let self else { return }
            self.log.receive(text, segmentID: id)
            if !text.isEmpty && self.hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            if mayContinue {
                if text.trimmed.isEmpty {
                    self.listening.suspend()
                    self.notice = "这一段没有听到内容，点「继续听」可以再试。"
                } else { self.resumeListening() }
            }
            else if let error = self.speech.errorText, self.listening.requested {
                self.listening.suspend()
                self.notice = error
            }
        }
        playback.$playback.sink { [weak self] snapshot in
            guard let self else { return }
            self.log.updatePlayback(snapshot)
            self.listening.playbackBusy = snapshot.phase.isBusy
            if snapshot.phase == .completed {
                if self.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                self.resumeListening()
            }
            if snapshot.phase == .failed || snapshot.phase == .stopped {
                self.listening.suspend()
                if snapshot.phase == .failed { self.notice = "这句没能播报。可以点重播，或放大给对方看。" }
            }
        }.store(in: &subscriptions)
        playback.$callActive.removeDuplicates().sink { [weak self] active in
            self?.listening.callActive = active
            if active {
                self?.pause(reason: "来电或通话中，现场转写已暂停。")
                if self?.isFaceToFace == true { self?.playback.stopSpeaking() }
            }
        }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification).receive(on: RunLoop.main).sink { [weak self] note in
            if (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue {
                self?.pause(reason: "声音被其他应用中断，请点「继续听」恢复。")
            }
        }.store(in: &subscriptions)
    }

    func switchScope(_ next: DialogueScope) {
        stopAll()
        guard next != scope else { return }
        savedScopes[scope] = (log, partnerDraft)
        let saved = savedScopes.removeValue(forKey: next)
        scope = next
        log = saved?.0 ?? ConversationLog()
        partnerDraft = saved?.1 ?? ""
        notice = ""
    }
    func resetScope(_ target: DialogueScope) {
        savedScopes.removeValue(forKey: target)
        if scope == target { clear() }
    }
    func setVisible(_ visible: Bool) {
        listening.visible = visible
        if !visible { pause() }
    }
    func setForeground(_ foreground: Bool) {
        listening.foreground = foreground
        if !foreground { pause(reason: "已离开应用，转写暂停；返回后点「继续听」。") }
    }
    func startListening() {
        guard listening.visible, listening.foreground, !playback.callActive else { return }
        // Stop an old playback first. Its stopped event must not cancel this new intent.
        playback.stopSpeaking()
        requestGeneration += 1
        let generation = requestGeneration
        listening.requested = true
        notice = ""
        permissionTask?.cancel()
        permissionTask = Task { [weak self] in
            guard let self, !Task.isCancelled, generation == self.requestGeneration, self.listening.canListen else { return }
            self.requesting = true
            defer { if self.requestGeneration == generation { self.requesting = false } }
            if !self.speech.authorized { await self.speech.requestAuthorization() }
            guard !Task.isCancelled, generation == self.requestGeneration, self.listening.canListen else { return }
            self.startMicrophone()
        }
    }
    func pause(reason: String = "") {
        requestGeneration += 1
        permissionTask?.cancel()
        restartTask?.cancel()
        requesting = false
        listening.suspend()
        speech.stop()
        if !reason.isEmpty { notice = reason }
    }
    func stopAll() {
        pause()
        playback.stopSpeaking()
    }
    func send(_ text: String, clearDraft: Bool = false, shortcutID: String? = nil) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        // Commit the live incoming line before appending the reply.
        speech.stop()
        guard let messageID = log.send(clean, shortcutID: shortcutID) else { return }
        if clearDraft { log.draft = "" }
        playMessage(messageID)
    }
    func sendTextOnly(_ text: String, clearDraft: Bool = false) {
        pause()
        playback.stopSpeaking()
        guard log.send(text, textOnly: true) != nil else { return }
        if clearDraft { log.draft = "" }
        notice = ""
    }
    func clearAllSessions() {
        clear()
        savedScopes.removeAll()
    }
    func playMessage(_ id: UUID) {
        guard let message = log.messages.first(where: { $0.id == id && $0.speaker == .me }) else { return }
        let continueAfter = listening.requested
        speech.stop()
        playback.stopSpeaking()
        listening.requested = continueAfter
        notice = ""
        let attemptID = UUID()
        log.beginPlayback(messageID: id, attemptID: attemptID)
        switch message.speechRoute {
        case .system:
            // Typed replies must start directly, even if their text matches a preset.
            playback.speak(message.text, usePreset: false, preferLocal: true, attemptID: attemptID)
        case .mimoShortcut:
            playback.speak(message.text, attemptID: attemptID, sourceID: message.shortcutID)
        }
    }
    func addTypedResponse(_ text: String) {
        pause()
        log.receive(text, segmentID: UUID(), typed: true)
        partnerDraft = ""
        notice = ""
    }
    func clear() {
        stopAll()
        log.clear()
        partnerDraft = ""
        notice = ""
    }
    private func startMicrophone() {
        guard listening.canListen, !speech.isRecording else { return }
        speech.start()
        if !speech.isRecording {
            listening.suspend()
            notice = speech.errorText ?? "暂时无法开始转写，请重试或请对方打字。"
        }
    }
    private func resumeListening() {
        guard listening.canListen, !requesting else { return }
        restartTask?.cancel()
        restartTask = Task { [weak self] in
            // Yield until the completed audio callback releases its session.
            await Task.yield()
            guard !Task.isCancelled, let self, self.listening.canListen else { return }
            self.startMicrophone()
        }
    }
}
