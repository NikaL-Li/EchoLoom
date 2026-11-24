import AVFAudio
import Accessibility
import Combine
import SwiftUI

enum CallInjectionState: String {
    case ready, waiting, off, systemDisabled, denied, undetermined, failed
    var title: String {
        switch self {
        case .ready: "通话注入已开启"
        case .waiting: "注入已开启 · 等待通话"
        case .off: "通话注入未开启"
        case .systemDisabled: "通话注入需系统设置"
        case .denied: "通话注入未授权"
        case .undetermined: "通话注入待授权"
        case .failed: "通话注入开启失败"
        }
    }
    var detail: String {
        switch self {
        case .ready: "系统已允许将播报音频加入当前通话。此状态不代表对方已经听到；系统通话静音时，注入也会静音。"
        case .waiting: "已开启播报注入，目前没有可用通话。接通支持的电话后，状态会自动更新。"
        case .off: "开启后，App 可以把播报音频加入支持的通话。尚未开启时，请勿以为对方能听到本机播报。"
        case .systemDisabled: "请到系统设置开启「通话中添加音频」，再返回这里开启注入。"
        case .denied: "请在系统设置中允许本 App 向通话添加音频，再返回这里开启。"
        case .undetermined: "先允许 App 向通话添加音频，再开启注入。"
        case .failed: "系统未能开启通话注入。请检查设置或重试；当前不会显示为已开启。"
        }
    }
    var symbol: String {
        switch self {
        case .ready: "phone.badge.waveform"
        case .waiting: "clock"
        case .off: "phone"
        default: "exclamationmark.circle"
        }
    }
    var needsSettings: Bool { self == .denied || self == .systemDisabled }
}

@MainActor
final class CallInjectionManager: NSObject, ObservableObject {
    @Published var permission: AVAudioApplication.MicrophoneInjectionPermission = .undetermined
    @Published var callActive = false
    @Published var injectionEnabled = false
    @Published var statusText = "未检查通话注入"
    @Published var lastSpoken = ""
    @Published var voiceGender = "female"
    @Published var voiceStatus = "语音播报"
    @Published var autoInjection: Bool = true
    @Published private(set) var playback = PlaybackSnapshot()
    @Published private(set) var outputNotice = ""
    private var currentUtterance: AVSpeechUtterance?
    private var interruptionObserver: NSObjectProtocol?
    private var audioSubscriptions = Set<AnyCancellable>()

    let customPhrases = CustomPhraseLibrary()
    private var systemSynthesizer: AVSpeechSynthesizer?
    private var presetPlayer: AVAudioPlayer?
    let playbackClock = PlaybackProgressClock()

    private var speechGeneration = 0
    private var capabilityObserver: NSObjectProtocol?
    private var mediaResetObserver: NSObjectProtocol?

    private let autoInjectionKey = "ylct.autoInjection"
    private var injectionFailed = false

    var injectionState: CallInjectionState {
        #if DEBUG && targetEnvironment(simulator)
        if let index = CommandLine.arguments.firstIndex(of: "--test-call-status"), CommandLine.arguments.indices.contains(index + 1),
           let state = CallInjectionState(rawValue: CommandLine.arguments[index + 1]) { return state }
        #endif
        switch permission {
        case .serviceDisabled: return .systemDisabled
        case .denied: return .denied
        case .undetermined: return .undetermined
        case .granted: break
        @unknown default: return .undetermined
        }
        if injectionFailed { return .failed }
        guard injectionEnabled else { return .off }
        return callActive ? .ready : .waiting
    }

    override init() {
        autoInjection = UserDefaults.standard.object(forKey: autoInjectionKey) as? Bool ?? true
        super.init()
        voiceGender = UserDefaults.standard.string(forKey: "ylct.voiceGender") == "male" ? "male" : "female"
        AVAudioSession.sharedInstance().publisher(for: \.outputVolume).receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshOutputNotice() }.store(in: &audioSubscriptions)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification).receive(on: RunLoop.main)
            .sink { [weak self] note in
                if (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt) == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                    self?.stopSpeaking()
                }
                self?.refreshOutputNotice()
            }.store(in: &audioSubscriptions)
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            let began = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue
            if began { Task { @MainActor in self?.stopSpeaking() } }
        }
    }

    func setAutoInjection(_ enabled: Bool) {
        autoInjection = enabled
        UserDefaults.standard.set(enabled, forKey: autoInjectionKey)
    }

    deinit {
        if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
        if let capabilityObserver { NotificationCenter.default.removeObserver(capabilityObserver) }
        if let mediaResetObserver { NotificationCenter.default.removeObserver(mediaResetObserver) }
    }

    func start() async {
        callActive = AVAudioSession.sharedInstance().isMicrophoneInjectionAvailable
        permission = AVAudioApplication.shared.microphoneInjectionPermission
        if autoInjection, permission == .granted {
            applyInjectionMode()
        }

        capabilityObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.microphoneInjectionCapabilitiesChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let available = note.userInfo?[AVAudioSessionMicrophoneInjectionIsAvailableKey] as? Bool ?? false
            Task { @MainActor in
                if !available, self?.playback.sourceID == "call.opening" { self?.stopSpeaking() }
                self?.callActive = available
                self?.permission = AVAudioApplication.shared.microphoneInjectionPermission
                if self?.permission != .granted { self?.injectionEnabled = false }
                if available, self?.injectionEnabled == true {
                    self?.applyInjectionMode()
                }
                self?.refreshStatus()
            }
        }

        mediaResetObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.injectionEnabled == true { self?.applyInjectionMode() }
                self?.refreshStatus()
            }
        }

        refreshStatus()
    }

    func refreshPermissions() {
        permission = AVAudioApplication.shared.microphoneInjectionPermission
        callActive = AVAudioSession.sharedInstance().isMicrophoneInjectionAvailable
        if permission != .granted { injectionEnabled = false }
        refreshStatus()
    }

    func requestAndEnable() async {
        refreshPermissions()
        if permission == .undetermined {
            permission = await AVAudioApplication.requestMicrophoneInjectionPermission()
        }
        guard permission == .granted else {
            injectionEnabled = false
            refreshStatus()
            return
        }
        applyInjectionMode()
        refreshStatus()
    }

    func disableInjection() {
        do { try AVAudioSession.sharedInstance().setPreferredMicrophoneInjectionMode(.none) }
        catch {
            injectionEnabled = AVAudioSession.sharedInstance().preferredMicrophoneInjectionMode == .spokenAudio
            statusText = "未能确认关闭，请检查系统通话设置后重试。"
            return
        }
        injectionEnabled = false
        injectionFailed = false
        refreshStatus()
    }

    func toggle() async {
        if injectionEnabled { disableInjection() } else { await requestAndEnable() }
    }

    var systemSpeechRate: Float = 0.48

    var voiceName: String { voiceGender == "male" ? "苏打" : "冰糖" }

    func setVoice(_ gender: String) {
        voiceGender = gender == "male" ? "male" : "female"
        UserDefaults.standard.set(voiceGender, forKey: "ylct.voiceGender")
    }

    func speak(_ text: String, usePreset: Bool = true, preferLocal: Bool = false, voiceOverride: String? = nil, attemptID: UUID = UUID(), sourceID: String? = nil) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        stopSpeaking()
        speechGeneration += 1
        let generation = speechGeneration
        lastSpoken = clean
        playback = PlaybackSnapshot(id: attemptID, phase: .preparing, sourceID: sourceID)
        do {
            let session = AVAudioSession.sharedInstance()
            if !callActive { try session.setCategory(.playback, mode: .spokenAudio, options: []) }
            try session.setActive(true)
            refreshOutputNotice()
        } catch {
            playback.phase = .failed
            return
        }
        if injectionEnabled { applyInjectionMode() }
        if sourceID == "call.opening", !canInjectOpening {
            playback.phase = .failed; return
        }
        lastSpoken = clean
        if preferLocal { speakLocal(clean, generation: generation); return }
        if usePreset, let phrase = customPhrases.phrase(matching: clean) {
            playCustomPhrase(phrase, gender: voiceOverride ?? voiceGender)
            return
        }
        if usePreset, playPreset(clean, voice: PhraseVoice(rawValue: voiceOverride ?? voiceGender) ?? .female) { return }
        // Only adding/editing a saved phrase may call MiMo. Typed replies and
        // variable order details use immediate native speech in either mode.
        speakLocal(clean, generation: generation)
    }

    var canInjectOpening: Bool {
        injectionState == .ready && AVAudioSession.sharedInstance().isMicrophoneInjectionAvailable &&
        AVAudioSession.sharedInstance().preferredMicrophoneInjectionMode == .spokenAudio &&
        AVAudioApplication.shared.microphoneInjectionPermission == .granted
    }
    func playOpening(_ text: String) {
        guard canInjectOpening else { return }
        speak(text, sourceID: "call.opening")
    }
    private func playCustomPhrase(_ phrase: CustomPhrase, gender: String) {
        guard customPhrases.ready(phrase) else {
            playback.phase = .failed
            outputNotice = "本机语音文件缺失，请到「我的常用语」重新生成。"
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: customPhrases.audioURL(phrase, gender: gender))
            player.volume = 1; player.delegate = self
            player.prepareToPlay(); presetPlayer = player
            guard player.play() else { throw CustomPhraseError.invalidAudio }
            beginProgressTracking(player: player)
            voiceStatus = "本机常用语 · \(gender == "male" ? "苏打" : "冰糖")"
        } catch {
            presetPlayer = nil; playback.phase = .failed
            outputNotice = "本机语音无法播放，请到「我的常用语」重新生成。"
        }
    }

    private func playPreset(_ text: String, voice: PhraseVoice) -> Bool {
        guard let resource = BundledReplyAudio.resourceName(text: text, voice: voice) else { return false }
        do {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else { throw CustomPhraseError.invalidAudio }
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.delegate = self
            player.prepareToPlay()
            presetPlayer = player
            guard player.play() else { throw CustomPhraseError.invalidAudio }
            beginProgressTracking(player: player)
            voiceStatus = "内置 MiMo · \(voice.name)"
        } catch {
            presetPlayer = nil
            playback.phase = .failed
            outputNotice = "内置语音文件无法播放，请更新 App 后重试。你也可以直接打字播报。"
        }
        // A broken bundled resource is an app problem, never a reason to make
        // the user generate a built-in reply or silently switch its voice.
        return true
    }

    private func speakLocal(_ text: String, generation: Int? = nil) {
        if let generation, generation != speechGeneration { return }
        voiceStatus = "本机系统语音"
        let synthesizer = systemSynthesizer ?? AVSpeechSynthesizer()
        if systemSynthesizer == nil { synthesizer.delegate = self; systemSynthesizer = synthesizer }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        guard let voice = preferredVoice() else { playback.phase = .failed; return }
        utterance.voice = voice
        utterance.rate = systemSpeechRate
        utterance.volume = 1.0
        // Start native speech immediately. Never wait to render the entire reply.
        currentUtterance = utterance
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        let stopped = playback.phase.isBusy ? playbackClock.finish(.stopped, fallback: playback) : nil
        speechGeneration += 1
        presetPlayer?.stop()
        presetPlayer = nil
        currentUtterance = nil
        systemSynthesizer?.stopSpeaking(at: .immediate)
        if let stopped { playback = stopped }
    }

    private func beginProgressTracking(player: AVAudioPlayer? = nil) {
        var snapshot = playback
        snapshot.phase = .playing
        snapshot.elapsed = player?.currentTime ?? 0
        snapshot.duration = player?.duration
        snapshot.spokenFraction = player == nil ? 0 : nil
        if let player {
            playbackClock.start(snapshot, audioPosition: { [weak player] in player?.currentTime ?? 0 })
        } else {
            playbackClock.start(snapshot)
        }
        // Only lifecycle changes reach AppState and conversation history.
        playback = snapshot
    }

    private func finishProgress(success: Bool) {
        playback = playbackClock.finish(success ? .completed : .failed, fallback: playback)
    }

    func refreshOutputNotice() {
        let session = AVAudioSession.sharedInstance()
        if session.outputVolume < 0.01 { outputNotice = "媒体音量为零，请按机身音量加键。" }
        else if !callActive, session.currentRoute.outputs.contains(where: { $0.portType != .builtInSpeaker && $0.portType != .builtInReceiver }) {
            outputNotice = "声音正通过耳机或外接设备播放，对方可能听不到。"
        } else { outputNotice = "" }
    }

    private func finishPlayer(_ player: AVAudioPlayer, success: Bool) {
        guard player === presetPlayer else { return }
        finishProgress(success: success)
        presetPlayer = nil
    }

    func openAccessibilitySettings() {
        Task {
            do {
                try await AccessibilitySettings.openSettings(for: .allowAppsToAddAudioToCalls)
            } catch {
                statusText = "请手动打开：设置 → 辅助功能 → 音频与视觉 → 通话中添加音频"
            }
        }
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let zhVoices = all.filter { $0.language == "zh-CN" }
        let selectedGender: AVSpeechSynthesisVoiceGender = voiceGender == "male" ? .male : .female
        let matching = zhVoices.filter { $0.gender == selectedGender }
        return matching.first(where: { $0.quality == .premium })
            ?? matching.first(where: { $0.quality == .enhanced })
            ?? matching.first
            ?? zhVoices.first(where: { $0.quality == .premium })
            ?? zhVoices.first(where: { $0.quality == .enhanced })
            ?? zhVoices.first
            ?? AVSpeechSynthesisVoice(language: "zh-CN")
    }

    private func applyInjectionMode() {
        do {
            try AVAudioSession.sharedInstance().setPreferredMicrophoneInjectionMode(.spokenAudio)
            injectionEnabled = true
            injectionFailed = false
            print("[YLCT] injection mode enabled")
        } catch {
            injectionEnabled = false
            injectionFailed = true
            print("[YLCT] injection mode failed: \(error.localizedDescription)")
        }
    }

    private func refreshStatus() {
        statusText = injectionState.title
    }
}

extension CallInjectionManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.currentUtterance === utterance, self.playback.phase.isBusy else { return }
            self.beginProgressTracking()
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.currentUtterance === utterance, self.playback.phase == .playing else { return }
            let length = (utterance.speechString as NSString).length
            guard length > 0, characterRange.location != NSNotFound else { return }
            // The callback announces the next word; count only text before it.
            self.playbackClock.updateSpokenFraction(Double(characterRange.location) / Double(length))
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.currentUtterance === utterance else { return }
            self.finishProgress(success: true)
            self.currentUtterance = nil
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.currentUtterance === utterance else { return }
            let stopped = self.playbackClock.finish(.stopped, fallback: self.playback)
            self.currentUtterance = nil
            self.playback = stopped
        }
    }
}
extension CallInjectionManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.finishPlayer(player, success: flag) }
    }
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in self.finishPlayer(player, success: false) }
    }
}
