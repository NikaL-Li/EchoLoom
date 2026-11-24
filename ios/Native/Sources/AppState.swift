import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var tab: YLCTTab = .home
    let universal = UniversalStore()
    @Published var activeScene: EverydaySceneDraft?
    @Published var sessionPreference: CommunicationPreference = .spokenReply
    @Published var startCaptionOnOpen = false
    @Published var mode: ServiceMode = .deliver
    @Published var address = AddressDraft()
    @Published var pickup = PickupDraft()
    let outdoors = HomeOutdoors()
    @Published var isLoggedIn = false
    @Published var userName = "游客"
    @Published var todayCount = 0
    @Published var weekCount = 0
    @Published var monthCount = 0
    @Published var yearCount = 0
    @Published var records: [DayRecord] = []
    @Published var toast: String?
    @Published var isRecognizing = false

    @Published var showAddress = false
    @Published var showPickup = false
    @Published var showDialogue = false
    @Published var showSign = false
    @Published var showPermissions = false
    @Published var showLogin = false

    let injection = CallInjectionManager()
    @Published var lastToolsNumber = ""
    lazy var opening = CallOpeningController(audio: injection)
    func openingText(for number: String) -> String? {
        let settings = universal.openings
        let id = settings.contact(number)?.phraseID ?? settings.phraseID
        return customPhrases.shortcuts(including: PhraseShortcut.faceTexts).first {
            $0.id == id && ($0.custom.map { customPhrases.ready($0) } ?? true)
        }?.text
    }
    var customPhrases: CustomPhraseLibrary { injection.customPhrases }
    let speech = SpeechRecognizer()
    let conversation: FaceToFaceConversation

    @Published private(set) var completedOrders: [CompletedOrder] = []
    @Published private(set) var recordError: String?
    @Published var activeDeliveryID: UUID?
    @Published var pendingDialogue = false
    @Published private(set) var dialogueEntry: DialogueEntry = .quickSpeech
    @Published var externalActionMessage: String?
    @Published private var quickDrafts: [DialogueScope: String] = [:]
    var quickSpeechDraft: String {
        get { quickDrafts[dialogueEntry.scope] ?? "" }
        set { quickDrafts[dialogueEntry.scope] = newValue }
    }
    private var pendingPhone: CustomerPhone?
    private var generatedAddressQuestion: String?
    private var returnToAddressAfterDialogue = false
    private var subscriptions = Set<AnyCancellable>()
    private let recordsKey = "ylct.native.completedOrders.v1"
    private var hasBootstrapped = false
    private var changingInjection = false

    var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: return "早上好，慢慢来，一路平安"
        case 11..<14: return "中午好，记得按时吃饭"
        case 14..<18: return "下午好，跑单也别忘休息"
        default: return "晚上好，今天也辛苦了"
        }
    }
    var currentDeliveryCompleted: Bool {
        guard let activeDeliveryID else { return false }
        return completedOrders.contains { $0.id == activeDeliveryID }
    }


    init() {
        conversation = FaceToFaceConversation(speech: speech, playback: injection)
        if let data = UserDefaults.standard.data(forKey: recordsKey) {
            do { completedOrders = try JSONDecoder().decode([CompletedOrder].self, from: data) }
            catch { recordError = "本机记录暂时无法读取，原数据已保留。" }
        }
        refreshRecordSummary()
        opening.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        universal.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        conversation.hapticsEnabled = universal.data.preferences.haptics
        customPhrases.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        conversation.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        // Forward nested ObservableObjects so transcripts, voices and permission status update live.
        injection.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        speech.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)

    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        await injection.start()
        speech.refreshStatus()
        // Communication starts independently of the optional home content.
        // Essential conversation features are available without logging in.
    }

    func refreshOnForeground() {
        injection.refreshPermissions()
        speech.refreshStatus()
        refreshRecordSummary()
    }

    func finishPermissionsIfNeeded() {
        // The onboarding sheet is controlled by RootView's AppStorage.
    }

    func openLogin() { showLogin = true }

    func login(phone: String, password: String) async throws {
        let user = try await BackendClient.login(phone: phone, password: password)
        isLoggedIn = true
        userName = user.nickname?.isEmpty == false ? (user.nickname ?? "骑手") : "骑手"
        showLogin = false
        showToast("登录成功；送餐记录保存在本机")
    }

    private func restoreSession() async {
        do {
            guard let user = try await BackendClient.currentUser() else { return }
            isLoggedIn = true
            userName = user.nickname?.isEmpty == false ? user.nickname! : "骑手"
        } catch {
            // Offline use remains available; never claim an unverified session or cloud sync.
        }
    }

    func logout() async {
        do {
            try await BackendClient.logout()
            isLoggedIn = false
            userName = "游客"
            showToast("已退出，本机记录已保留")
        } catch { showToast("退出失败，请检查网络后重试") }
    }

    func openAddress() {
        activeScene = nil
        mode = .deliver
        if activeDeliveryID == nil || currentDeliveryCompleted {
            if currentDeliveryCompleted { address = AddressDraft() }
            activeDeliveryID = UUID()
            conversation.resetScope(.delivery)
            quickDrafts[.delivery] = nil
            generatedAddressQuestion = nil
        }
        showAddress = true
    }
    func openPickup() { activeScene = nil; mode = .pickup; showPickup = true }
    func openDialogue(entry: DialogueEntry = .quickSpeech) {
        activeScene = nil
        startCaptionOnOpen = false
        sessionPreference = universal.data.preferences.communication
        pendingPhone = nil
        configureDialogue(entry)
        showDialogue = true
    }
    func openGeneralConversation(style: CommunicationPreference? = nil, phone: Bool = false, startCaptions: Bool = false) {
        openDialogue(entry: phone ? .quickSpeech : .faceToFace)
        sessionPreference = style ?? universal.data.preferences.communication
        startCaptionOnOpen = startCaptions && !phone
        conversation.hapticsEnabled = universal.data.preferences.haptics
    }
    func openSceneConversation(_ scene: EverydaySceneDraft, phone: Bool = false) {
        pendingPhone = nil
        activeScene = scene
        sessionPreference = universal.data.preferences.communication
        startCaptionOnOpen = false
        conversation.hapticsEnabled = universal.data.preferences.haptics
        configureDialogue(.scene(scene.id, phone: phone))
        showDialogue = true
    }
    var visibleBuiltIns: [String] {
        var values = PhraseShortcut.faceTexts
        if universal.data.preferences.riderScenes { values += PhraseShortcut.riderTexts }
        return values
    }
    func visibleShortcuts(including texts: [String]) -> [PhraseShortcut] {
        let shortcuts = customPhrases.shortcuts(including: texts)
        return shortcuts
    }
    func saveCurrentConversation() -> Bool {
        conversation.pause()
        return universal.saveConversation(id: conversation.log.sessionID, title: activeScene?.displayTitle ?? "面对面沟通", messages: conversation.log.messages)
    }
    private func configureDialogue(_ entry: DialogueEntry) {
        if dialogueEntry.scope != entry.scope { injection.lastSpoken = "" }
        conversation.switchScope(entry.scope)
        dialogueEntry = entry
        if let serviceMode = entry.serviceMode { mode = serviceMode }
        conversation.isFaceToFace = entry.startsFaceToFace
    }
    func openSign() { showSign = true }
    func prepareAddressQuestion() {
        generatedAddressQuestion = address.confirmationQuestion
        quickSpeechDraft = address.confirmationQuestion
    }
    func continueToDialogue(call: CustomerPhone? = nil) {
        if mode == .deliver, let generatedAddressQuestion, quickDrafts[.delivery] == generatedAddressQuestion {
            quickDrafts[.delivery] = address.confirmationQuestion
            self.generatedAddressQuestion = address.confirmationQuestion
        }
        configureDialogue(mode == .deliver ? .delivery : .pickup)
        pendingPhone = call
        pendingDialogue = true
        showAddress = false
        showPickup = false
    }
    func formDidDismiss() {
        guard pendingDialogue else { return }
        pendingDialogue = false
        showDialogue = true
    }

    func returnToDeliveryAddress() {
        conversation.stopAll()
        pendingPhone = nil
        returnToAddressAfterDialogue = true
        showDialogue = false
    }
    func dialogueDidDismiss() {
        pendingPhone = nil
        guard returnToAddressAfterDialogue else { return }
        returnToAddressAfterDialogue = false
        // Editing/navigation must keep the same order, even if it was marked done.
        mode = .deliver
        showAddress = true
    }
    func consumePendingPhone() {
        guard let phone = pendingPhone else { return }
        pendingPhone = nil
        dialCustomer(phone)
    }
    func dialCustomer(_ phone: CustomerPhone, useOpening: Bool = false) {
        conversation.stopAll()
        conversation.isFaceToFace = false
        let id: UUID?
        if useOpening, universal.openings.automatic, injection.injectionEnabled, let phrase = openingText(for: phone.number) {
            id = opening.prepare(text: phrase, delay: universal.openings.delay)
        } else { opening.cancel(""); id = nil }
        openExternal(phone.url, failure: "未能打开电话。请复制号码后，在电话 App 中拨号。") { [weak self] ok in self?.opening.opened(ok, id: id) }
    }
    func openExternal(_ url: URL, failure: String, reportsGlobally: Bool = true, completion: ((Bool) -> Void)? = nil) {
        #if DEBUG && targetEnvironment(simulator)
        // Explicit UI-test interception: tests must never place actual calls.
        if CommandLine.arguments.contains("--test-external-links") {
            if reportsGlobally { externalActionMessage = "测试链接：\(url.absoluteString)" }
            completion?(false)
            return
        }
        #endif
        UIApplication.shared.open(url, options: [:]) { [weak self] opened in
            Task { @MainActor in completion?(opened); if !opened && reportsGlobally { self?.externalActionMessage = failure } }
        }
    }

    @discardableResult func completeOrder(id: UUID = UUID()) -> Bool {
        guard recordError == nil else { showToast(recordError!); return false }
        guard !completedOrders.contains(where: { $0.id == id }) else { return false }
        var updated = completedOrders
        updated.append(CompletedOrder(id: id, completedAt: Date()))
        guard saveOrders(updated) else { return false }
        showToast("已记下这一单，辛苦了")
        return true
    }

    func undoLastOrder() {
        guard let last = completedOrders.last else { return }
        guard saveOrders(completedOrders.filter { $0.id != last.id }) else { return }
        showToast("已撤销上一条记录")
    }

    private func saveOrders(_ orders: [CompletedOrder]) -> Bool {
        guard recordError == nil else { return false }
        do {
            let data = try JSONEncoder().encode(orders)
            UserDefaults.standard.set(data, forKey: recordsKey)
            completedOrders = orders
            refreshRecordSummary()
            return true
        } catch { showToast("记录保存失败，请重试"); return false }
    }

    func refreshRecordSummary() {
        let summary = OrderHistory.summary(completedOrders)
        todayCount = summary.today
        weekCount = summary.week
        monthCount = summary.month
        yearCount = summary.year
        records = summary.days
    }

    func showToast(_ message: String) {
        toast = message
    }

    func speak(_ text: String, usePreset: Bool = true, sourceID: String? = nil) {
        if opening.pending { opening.cancel("已改为手动播报。") }
        if speech.isRecording { speech.stop() }
        injection.speak(text, usePreset: usePreset, sourceID: sourceID)
    }

    func toggleInjection() async {
        guard !changingInjection else { return }
        changingInjection = true
        defer { changingInjection = false }
        await injection.toggle()
        showToast(injection.statusText)
    }

    func recognizeScreenshot(_ data: Data, pickup target: Bool) async -> String {
        isRecognizing = true
        defer { isRecognizing = false }
        do {
            let text = try await BackendClient.ocr(imageData: data)
            try Task.checkCancellation()
            let changed = target ? applyPickupText(text) : applyAddressText(text)
            return changed ? "已填入识别结果，请核对后继续。" : "已识别文字，但未找到明确的地址或取餐字段，请手动填写。"
        } catch {
            return "识别失败：\(error.localizedDescription)"
        }
    }

    @discardableResult func applyAddressText(_ text: String) -> Bool {
        let result = ScreenshotParser.address(text)
        var found = false
        if !result.phone.isEmpty { address.phone = result.phone; found = true }
        if !result.floor.isEmpty { address.floor = result.floor; found = true }
        if !result.room.isEmpty { address.room = result.room; found = true }
        if !result.building.isEmpty { address.building = result.building; found = true }
        if !result.community.isEmpty { address.community = result.community; found = true }
        return found
    }

    @discardableResult func applyPickupText(_ text: String) -> Bool {
        let result = ScreenshotParser.pickup(text)
        var found = false
        if !result.phone.isEmpty { pickup.phone = result.phone; found = true }
        if !result.code.isEmpty { pickup.code = result.code; found = true }
        if !result.merchant.isEmpty { pickup.merchant = result.merchant; found = true }
        if !result.address.isEmpty { pickup.address = result.address; found = true }
        return found
    }
}
