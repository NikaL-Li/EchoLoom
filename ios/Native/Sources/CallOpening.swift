import CallKit
import UIKit
import Combine

@MainActor
final class CallOpeningController: NSObject, ObservableObject, CXCallObserverDelegate {
    @Published private(set) var notice = ""
    @Published private(set) var pending = false
    private let observer = CXCallObserver()
    private weak var audio: CallInjectionManager?
    private var window: OpeningWindow?
    private var text = ""
    private var lastEvaluation: TimeInterval = 0
    private var accepted = false
    private var token = UUID()
    private var timer: Task<Void, Never>?
    private var background: UIBackgroundTaskIdentifier = .invalid
    private var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }
    private var lines: [ObservedLine] {
        observer.calls.map { ObservedLine(id: $0.uuid, outgoing: $0.isOutgoing, connected: $0.hasConnected, ended: $0.hasEnded, held: $0.isOnHold) }
    }
    init(audio: CallInjectionManager) {
        self.audio = audio
        super.init()
        observer.setDelegate(self, queue: .main)
    }
    nonisolated func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        MainActor.assumeIsolated {
            objectWillChange.send()
            if window != nil, call.hasEnded || call.isOnHold || (window?.line != nil && call.uuid != window?.line) {
                cancel("通话状态已变化，开场已取消。")
            } else { evaluate() }
        }
    }
    func prepare(text: String, delay: Int) -> UUID? {
        cancel("")
        guard lines.allSatisfy({ $0.ended }) else { notice = "已有通话，请手动播报开场。"; return nil }
        self.text = text
        accepted = false
        lastEvaluation = uptime
        window = OpeningWindow(requested: uptime, delay: Double(delay))
        token = UUID()
        let id = token
        pending = true
        notice = "等待本次外呼接通"
        background = UIApplication.shared.beginBackgroundTask(withName: "等待通话开场") { [weak self] in
            MainActor.assumeIsolated { if self?.token == id { self?.cancel("后台等待已结束，可手动播报。") } }
        }
        timer = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                guard let self, self.token == id else { return }
                self.evaluate()
            }
        }
        return id
    }
    func returnedToApp() {
        if pending, window?.line == nil, lines.allSatisfy({ $0.ended }) {
            cancel("没有观察到本次外呼，未播报。")
        }
    }
    func opened(_ success: Bool, id: UUID?) {
        guard let id, id == token, window != nil else { return }
        if success { accepted = true; evaluate() } else { cancel("拨号已取消，未播报。") }
    }
    func cancel(_ message: String) {
        if window != nil, audio?.playback.sourceID == "call.opening", audio?.playback.phase.isBusy == true { audio?.stopSpeaking() }
        token = UUID(); window = nil; timer?.cancel(); timer = nil
        endBackground(); pending = false; notice = message
    }
    private func endBackground() {
        if background != .invalid { UIApplication.shared.endBackgroundTask(background); background = .invalid }
    }
    private func evaluate() {
        guard var w = window, let audio else { return }
        let now = uptime
        guard w.consumed || now - lastEvaluation <= 3 else { cancel("已错过开场时机，可手动播报。"); return }
        lastEvaluation = now
        let state = w.check(lines, now: now, accepted: accepted, ready: audio.canInjectOpening && !audio.playback.phase.isBusy)
        window = w
        switch state {
        case .cancel: cancel(w.consumed ? "" : "未播报开场；需要时可手动播报。")
        case .wait:
            if w.due != nil && !w.consumed && notice != "已接通，等待播报开场" { notice = "已接通，等待播报开场" }
        case .play:
            pending = false
            audio.playOpening(text)
            notice = audio.playback.phase == .failed ? "未能加入通话，请检查注入状态。" : "本次已发起开场播报"
            timer?.cancel(); timer = nil; endBackground()
        }
    }
    var canPlayManually: Bool {
        let live = lines.filter { !$0.ended }
        return live.count == 1 && live[0].connected && !live[0].held && audio?.canInjectOpening == true
    }
    func manual(_ text: String) {
        guard canPlayManually, let call = lines.first(where: { !$0.ended }) else { notice = "请在单路通话接通且注入可用后播报。"; return }
        cancel("")
        window = OpeningWindow(requested: uptime, delay: 0, line: call.id, consumed: true)
        audio?.playOpening(text)
        notice = audio?.playback.phase == .failed ? "未能加入通话，请检查注入状态。" : "本次已发起开场播报"
    }
}
