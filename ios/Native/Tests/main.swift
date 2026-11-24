import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    checks += 1
    guard condition() else { fatalError("FAIL: \(name)") }
    print("PASS: \(name)")
}
func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
func order(_ value: String) -> CompletedOrder { CompletedOrder(id: UUID(), completedAt: date(value)) }
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
let now = date("2026-01-02T12:00:00+08:00")
let orders = [order("2026-01-02T08:00:00+08:00"), order("2026-01-01T23:59:59+08:00"), order("2025-12-31T23:00:00+08:00"), order("2025-12-27T00:00:00+08:00"), order("2025-12-26T23:59:59+08:00"), order("2026-01-03T00:00:00+08:00")]
let summary = OrderHistory.summary(orders, now: now, calendar: calendar)
check(summary.today == 1, "today uses local calendar boundary")
check(summary.week == 4, "rolling seven days includes correct start and excludes future")
check(summary.month == 2, "month resets across new year")
check(summary.year == 2, "year excludes prior-year orders")
check(summary.days.count == 30, "history contains all thirty days")
check(summary.days[0].date == "2026-01-02", "date keys are stable and zero-padded")
check(summary.days[1].label == "昨天", "relative day labels match actual calendar")
check(summary.days[2].label == "12月31日", "cross-year day label is real")
let empty = OrderHistory.summary([], now: now, calendar: calendar)
check(empty.today == 0 && empty.week == 0 && empty.month == 0 && empty.year == 0, "empty install has no demo counts")
check(empty.days.allSatisfy { $0.count == 0 }, "empty days stay zero")
let roundTrip = try JSONDecoder().decode([CompletedOrder].self, from: JSONEncoder().encode(orders))
check(roundTrip.map(\.id) == orders.map(\.id), "saved identities survive relaunch")
check(OrderHistory.summary(roundTrip, now: now, calendar: calendar).today == 1, "saved counts survive relaunch")
var dst = Calendar(identifier: .gregorian)
dst.timeZone = TimeZone(identifier: "America/Los_Angeles")!
let dstSummary = OrderHistory.summary([order("2026-03-08T01:30:00-08:00"), order("2026-03-08T03:30:00-07:00")], now: date("2026-03-08T20:00:00-07:00"), calendar: dst)
check(dstSummary.today == 2, "day aggregation survives daylight-saving transition")
check(Set(dstSummary.days.map(\.date)).count == 30, "daylight-saving history has no duplicate dates")
let phone = ScreenshotParser.address("顾客电话：13800000000")
check(phone.phone == "13800000000", "OCR extracts full mobile number")
check(phone.room.isEmpty, "mobile number cannot become room number")
check(ScreenshotParser.address("中山路1234号").room.isEmpty, "street number cannot become room number")
let address = ScreenshotParser.address("幸福花园 A栋 1502室 15楼\n电话 13800000000")
check(address.building == "A" && address.room == "1502" && address.floor == "15", "explicit building room and floor markers parse")
check(ScreenshotParser.address("房号：B1203").room == "B1203", "explicit room label supports letter prefix")
let pickup = ScreenshotParser.pickup("星光咖啡店\n取餐码：A123\n手机尾号：6789\n海滨路20号")
check(pickup.code == "A123" && pickup.phone == "6789", "pickup code and phone suffix stay separate")
check(pickup.merchant == "星光咖啡店" && pickup.address == "海滨路20号", "merchant and pickup location parse")
check(ScreenshotParser.pickup("手机尾号：6789").code.isEmpty, "phone suffix does not masquerade as pickup code")
check(ScreenshotParser.pickup("单号：123456789012345").code.isEmpty, "long order ID is not truncated into a pickup code")
check(ScreenshotParser.address("优惠满30减5").community.isEmpty, "promotional text cannot become an address")
check(ScreenshotParser.address("").phone.isEmpty && ScreenshotParser.pickup("").code.isEmpty, "empty OCR does not invent fields")
print("\(checks) regression checks passed.")

var chat = ConversationLog()
let segment = UUID()
chat.receive("  请走东门  ", segmentID: segment)
chat.receive("重复的回调", segmentID: segment)
check(chat.messages.count == 1 && chat.messages[0].text == "请走东门", "recognition segment commits only once")
chat.receive("请走东门", segmentID: UUID())
check(chat.messages.count == 2, "separate repeated utterances remain separate messages")
chat.receive(" \n ", segmentID: UUID())
check(chat.messages.count == 2, "empty recognition never creates a bubble")
check(chat.send(" \n ") == nil, "empty reply cannot be sent")
chat.draft = "还没有写完"
let reply = chat.send("好的，请稍等")!
check(chat.messages.last?.speaker == .me && chat.messages.last?.text == "好的，请稍等", "reply follows incoming transcript in conversation")
check(chat.draft == "还没有写完", "quick reply does not erase typed draft")
let oldAttempt = UUID(), newAttempt = UUID()
chat.beginPlayback(messageID: reply, attemptID: oldAttempt)
chat.updatePlayback(PlaybackSnapshot(id: oldAttempt, phase: .playing))
check(chat.messages.last?.playback == .playing, "current playback reports actual playing state")
chat.updatePlayback(PlaybackSnapshot(id: oldAttempt, phase: .stopped))
chat.updatePlayback(PlaybackSnapshot(id: oldAttempt, phase: .completed))
check(chat.messages.last?.playback == .stopped, "late finish cannot turn cancelled playback into success")
chat.beginPlayback(messageID: reply, attemptID: newAttempt)
chat.updatePlayback(PlaybackSnapshot(id: oldAttempt, phase: .completed))
check(chat.messages.last?.playback == .preparing, "old audio callback cannot complete newer replay")
chat.updatePlayback(PlaybackSnapshot(id: newAttempt, phase: .failed))
check(chat.messages.last?.playback == .failed, "audio failure stays visible and can be retried")
chat.beginPlayback(messageID: reply, attemptID: UUID())
let currentAttempt = chat.messages.last!.playbackID!
chat.updatePlayback(PlaybackSnapshot(id: currentAttempt, phase: .completed))
check(chat.messages.count == 3 && chat.messages.last?.playback == .completed, "replay updates original bubble without duplicating message")
var gate = ConversationListeningGate()
check(!gate.canListen, "opening conversation never silently enables microphone")
gate.visible = true; gate.requested = true
check(gate.canListen, "explicit listening intent in foreground permits recognition")
gate.playbackBusy = true
check(!gate.canListen, "reply audio pauses recognition to avoid self-transcription")
gate.playbackBusy = false
check(gate.canListen, "completed audio restores previously requested listening")
gate.suspend()
check(!gate.canListen, "manual pause prevents automatic microphone restart")
gate.requested = true; gate.foreground = false
check(!gate.canListen, "background blocks recognition")
gate.foreground = true; gate.callActive = true
check(!gate.canListen, "phone call blocks face-to-face microphone")
gate.callActive = false; gate.visible = false
check(!gate.canListen, "dismissed or covered conversation cannot restart microphone")
chat.clear()
check(chat.messages.isEmpty && chat.draft.isEmpty, "clear removes both conversation and draft")
chat.updatePlayback(PlaybackSnapshot(id: currentAttempt, phase: .completed))
check(chat.messages.isEmpty, "late audio callback cannot resurrect cleared history")
print("Total: \(checks) regression checks passed.")

check(DialogueEntry.faceToFace.startsFaceToFace, "home face-to-face entrance starts the requested mode")
check(!DialogueEntry.delivery.startsFaceToFace && !DialogueEntry.pickup.startsFaceToFace, "order flows always start quick speech independently of home selection")
check(DialogueEntry.faceToFace.scope == DialogueEntry.quickSpeech.scope && DialogueEntry.delivery.scope != DialogueEntry.faceToFace.scope, "home and delivery conversation scopes are distinct")
check(DialogueEntry.quickSpeech.serviceMode == nil && DialogueEntry.delivery.serviceMode == .deliver, "home shortcut does not carry an old delivery context")
check(CustomerPhone("138 0000 0000")?.number == "13800000000", "phone permits readable mobile formatting")
check(CustomerPhone("１３８００００００００")?.number == "13800000000", "fullwidth pasted phone is normalized without changing digits")
check(CustomerPhone("(010) 1234-5678")?.number == "01012345678", "area-code landline formatting is accepted")
check(CustomerPhone("+86 13800000000")?.url.absoluteString == "tel:+8613800000000", "international mobile uses exact tel destination")
check(CustomerPhone("+86 10 12345678") != nil, "international Beijing landline is accepted")
check(CustomerPhone("400-123-4567") != nil, "full service number is accepted")
for invalid in ["6789", "138****0000", "138xxxx0000", "tel:13800000000", "13800000000#123", "13800000000;123", "13800000000,123", "13800000000转123", "110", "+8612345678", "13800000000\n13900000000", ""] {
 check(CustomerPhone(invalid) == nil, "unsafe incomplete or ambiguous phone rejected: \(invalid)")
}
var destination = AddressDraft()
destination.community = "  杭州市 西湖 A+B&东门#2  "
destination.building = "A"; destination.room = "1502"; destination.floor = "15"; destination.note = "门禁密码不要带进地图"
check(destination.navigationQuery == "杭州市 西湖 A+B&东门#2", "maps destination uses explicit location text only")
let mapURL = OrderNavigationLink.url(for: destination.navigationQuery)!
let mapComponents = URLComponents(url: mapURL, resolvingAgainstBaseURL: false)!
check(mapComponents.host == "maps.apple.com" && mapComponents.path == "/directions", "navigation targets system Maps directions endpoint")
check(mapComponents.queryItems?.first(where: { $0.name == "destination" })?.value == destination.navigationQuery, "Chinese spaces plus ampersand and hash survive maps encoding")
check(mapComponents.queryItems?.count == 2 && mapComponents.fragment == nil, "address cannot inject extra maps parameters or fragment")
check(mapComponents.queryItems?.first(where: { $0.name == "mode" })?.value == "cycling", "rider preview defaults to cycling")
check(mapComponents.queryItems?.contains(where: { $0.name == "start" }) == false, "route link never auto-starts navigation")
check(!mapURL.absoluteString.contains("1502") && !mapURL.absoluteString.contains("15%E6%A5%BC"), "room and floor stay in order instead of route request")
check(OrderNavigationLink.url(for: " \n ") == nil, "blank address cannot open a meaningless route")
let legacy = URLComponents(url: OrderNavigationLink.url(for: "杭州西湖", unified: false)!, resolvingAgainstBaseURL: false)!
check(legacy.queryItems?.first?.name == "q", "legacy cycling opens destination without assuming a driving route")
check(destination.confirmationQuestion.contains("1502室") && !destination.confirmationQuestion.contains(destination.note), "address question includes delivery detail without automatically speaking private notes")
check(AddressDraft().confirmationQuestion.isEmpty, "missing address produces no misleading confirmation question")
var audioProgress = PlaybackSnapshot(id: UUID(), phase: .preparing, sourceID: "quick.test")
check(audioProgress.progress == 0 && audioProgress.timingLabel == "准备好后开始", "preparation never advances the playback bar")
audioProgress.phase = .playing
audioProgress.duration = 4.8
audioProgress.elapsed = 2.4
check(audioProgress.progress == 0.5 && audioProgress.percent == 50, "file progress uses elapsed time divided by actual duration")
check(audioProgress.timingLabel == "0:02 / 0:05", "audio timing remains readable for fractional durations")
audioProgress.elapsed = 4.8
check(audioProgress.progress < 1, "reaching the sampled duration cannot claim playback completed")
audioProgress.phase = .stopped
check(audioProgress.progress < 1 && audioProgress.accessibilityValue.contains("已停止"), "stop at the end is still not reported as successful completion")
audioProgress.phase = .completed
check(audioProgress.progress == 1 && audioProgress.timingLabel == "0:05 / 0:05", "the successful completion callback fills the bar and aligns both clocks")
var localProgress = PlaybackSnapshot(id: UUID(), phase: .playing, elapsed: 2, spokenFraction: 0.4)
check(localProgress.progress == 0.4 && localProgress.timingLabel == "系统语音 · 已播 0:02", "direct speech shows elapsed time without inventing a total duration or audio percentage")
localProgress.phase = .completed
check(localProgress.percent == 100 && localProgress.timingLabel == "已全部播完", "system speech completion also reaches full progress")
localProgress.phase = .failed
check(localProgress.percent == 40 && localProgress.accessibilityValue.contains("未能播报"), "failed playback retains its last position without looking completed")
check(PlaybackSnapshot(phase: .playing, elapsed: .infinity, duration: 3).progress == 0, "nonfinite audio timing cannot corrupt progress layout")
check(PlaybackSnapshot(phase: .playing, elapsed: -5, duration: 3).progress == 0, "negative audio timing clamps to zero")
check(PlaybackSnapshot(phase: .playing, duration: 0).progress == 0, "unknown duration cannot divide by zero")
check(PlaybackSnapshot(phase: .playing, spokenFraction: 2).progress == 0.99, "word range cannot prematurely finish the progress bar")
var progressChat = ConversationLog()
let progressMessage = progressChat.send("请在东门等我，我马上到。")!
let firstPlayback = UUID(), secondPlayback = UUID()
progressChat.beginPlayback(messageID: progressMessage, attemptID: firstPlayback)
progressChat.updatePlayback(PlaybackSnapshot(id: firstPlayback, phase: .playing, elapsed: 1, duration: 4))
check(progressChat.messages[0].playbackSnapshot.progress == 0.25, "conversation bubble receives live progress for its own audio attempt")
progressChat.updatePlayback(PlaybackSnapshot(id: firstPlayback, phase: .stopped, elapsed: 1.5, duration: 4))
progressChat.updatePlayback(PlaybackSnapshot(id: firstPlayback, phase: .completed, elapsed: 4, duration: 4))
check(progressChat.messages[0].playbackSnapshot.progress == 0.375, "late completion preserves a stopped bubble and its partial progress")
progressChat.beginPlayback(messageID: progressMessage, attemptID: secondPlayback)
check(progressChat.messages[0].playbackSnapshot.progress == 0 && progressChat.messages[0].playbackSnapshot.duration == nil, "replay resets timing before the new audio starts")
progressChat.updatePlayback(PlaybackSnapshot(id: firstPlayback, phase: .playing, elapsed: 3, duration: 4))
check(progressChat.messages[0].playbackSnapshot.phase == .preparing, "old progress callbacks cannot advance a newer replay")
progressChat.updatePlayback(PlaybackSnapshot(id: secondPlayback, phase: .completed, elapsed: 4, duration: 4))
let nextMessage = progressChat.send("谢谢。")!
let thirdPlayback = UUID()
progressChat.beginPlayback(messageID: nextMessage, attemptID: thirdPlayback)
progressChat.updatePlayback(PlaybackSnapshot(id: thirdPlayback, phase: .playing, elapsed: 1, duration: 2))
check(progressChat.messages[0].playbackSnapshot.progress == 1 && progressChat.messages[1].playbackSnapshot.progress == 0.5, "new playback leaves completed historical bubbles intact")
MainActor.assumeIsolated {
    var uptime: TimeInterval = 100
    var audioPosition: TimeInterval = 0
    var audioReads = 0
    let clock = PlaybackProgressClock(now: { uptime })
    let attempt = PlaybackSnapshot(id: UUID(), phase: .playing, duration: 10)
    clock.start(attempt, audioPosition: { audioReads += 1; return audioPosition })
    uptime = 200
    check(clock.sample(fallback: attempt).progress == 0, "a stalled audio clock cannot be advanced by elapsed wall time")
    var frameProgress: [Double] = []
    for frame in 1...60 {
        audioPosition = Double(frame) / 60
        frameProgress.append(clock.sample(fallback: attempt).progress)
    }
    check(Set(frameProgress).count == 60, "frame sampling preserves all 60 distinct audio positions instead of ten jumps")
    check(abs(frameProgress.last! - 0.1) < 0.000001, "smooth rendering still tracks the real audio position exactly")
    audioPosition = 0
    check(clock.sample(fallback: attempt).elapsed == 1, "a player clock reset cannot move the visible bar backwards")
    let historical = PlaybackSnapshot(id: UUID(), phase: .stopped, elapsed: 2, duration: 5)
    let readsBeforeHistory = audioReads
    check(clock.sample(fallback: historical) == historical && audioReads == readsBeforeHistory, "old messages keep their progress and never poll the active player")
    audioPosition = 3.75
    let stopped = clock.finish(.stopped, fallback: attempt)
    check(stopped.elapsed == 3.75 && stopped.phase == .stopped, "stopping samples the latest position even between rendered frames")
    audioPosition = 9
    let readsAfterStop = audioReads
    check(clock.sample(fallback: stopped) == stopped && audioReads == readsAfterStop, "stopped playback is static and releases its audio polling closure")
    let replay = PlaybackSnapshot(id: UUID(), phase: .playing, duration: 4)
    audioPosition = 0
    clock.start(replay, audioPosition: { audioReads += 1; return audioPosition })
    check(clock.sample(fallback: replay).progress == 0, "new playback starts from zero without interpolating backwards")
    check(clock.sample(fallback: attempt) == attempt, "an obsolete rendering pass cannot read the newer audio clock")
    audioPosition = 4
    check(clock.sample(fallback: replay).progress == 0.99, "frame sampling cannot prematurely mark audio complete")
    let finished = clock.finish(.completed, fallback: replay)
    check(finished.progress == 1 && finished.elapsed == 4, "only completion marks the new audio fully played")
    let preparing = PlaybackSnapshot(id: UUID(), phase: .preparing)
    check(clock.finish(.stopped, fallback: preparing).elapsed == 0, "cancelling preparation does not inherit the previous audio duration")
    let speechAttempt = PlaybackSnapshot(id: UUID(), phase: .playing, spokenFraction: 0)
    uptime = 300
    clock.start(speechAttempt)
    uptime = 310
    check(clock.sample(fallback: speechAttempt).progress == 0, "local speech never invents word progress from elapsed seconds")
    clock.updateSpokenFraction(0.35)
    let spoken = clock.sample(fallback: speechAttempt)
    check(spoken.progress == 0.35 && spoken.elapsed == 10, "local speech uses reported text position and separate elapsed time")
    clock.updateSpokenFraction(0.1)
    clock.updateSpokenFraction(.nan)
    check(clock.sample(fallback: speechAttempt).progress == 0.35, "late or invalid word callbacks cannot regress local speech progress")
    let speechStopped = clock.finish(.stopped, fallback: speechAttempt)
    clock.updateSpokenFraction(1)
    uptime = 320
    check(clock.sample(fallback: speechStopped) == speechStopped, "cancelled local speech ignores late words and time changes")
}
var routeChat = ConversationLog()
let sameText = "好的，谢谢！"
let typedID = routeChat.send(sameText)!
let shortcutID = routeChat.send(sameText, shortcutID: "builtin.\(sameText)")!
check(routeChat.messages[0].speechRoute == .system, "typed text always uses native speech even if it matches a shortcut")
check(routeChat.messages[1].speechRoute == .mimoShortcut, "tapping a shortcut explicitly selects cached MiMo audio")
let shortcutAttempt = UUID()
routeChat.beginPlayback(messageID: shortcutID, attemptID: shortcutAttempt)
routeChat.updatePlayback(PlaybackSnapshot(id: shortcutAttempt, phase: .stopped))
routeChat.beginPlayback(messageID: shortcutID, attemptID: UUID())
check(routeChat.messages[1].shortcutID == "builtin.\(sameText)" && routeChat.messages[1].speechRoute == .mimoShortcut, "stopping and replaying retain the shortcut source")
routeChat.beginPlayback(messageID: typedID, attemptID: UUID())
check(routeChat.messages[0].shortcutID == nil && routeChat.messages[0].speechRoute == .system, "replaying typed text keeps the immediate native route")
print("Final total: \(checks) regression checks passed.")
