import Foundation
import Combine

// Communication preferences describe a workflow, never a medical category.
enum CommunicationPreference: String, Codable, CaseIterable, Identifiable {
    case spokenReply, captions, textOnly
    var id: String { rawValue }
    var title: String { switch self { case .captions: "实时字幕"; case .spokenReply: "打字播报"; case .textOnly: "双向打字" } }
    var detail: String { switch self { case .captions: "我可以自己说话，需要时再展开回复区"; case .spokenReply: "我打字，手机帮我说；也可以看对方说话的字幕"; case .textOnly: "双方轮流打字，不自动开启麦克风或播报" } }
    var icon: String { switch self { case .captions: "captions.bubble"; case .spokenReply: "keyboard"; case .textOnly: "text.bubble" } }
    var displayText: String { switch self { case .captions: "我在看语音字幕。\n请面对我，一次说一句。"; case .spokenReply: "我用文字回复。\n请稍等，我正在打字。"; case .textOnly: "我们用文字交流。\n请把想说的话打字给我看。" } }
}

enum EverydaySceneKind: String, Codable, CaseIterable, Identifiable {
    case shopping, dining, travel, stay, health, service, work, personal
    var id: String { rawValue }
    var title: String { switch self { case .shopping: "购物"; case .dining: "餐饮"; case .travel: "交通出行"; case .stay: "住宿"; case .health: "就医"; case .service: "窗口办事"; case .work: "工作学习"; case .personal: "自定义场景" } }
    var icon: String { switch self { case .shopping: "bag"; case .dining: "fork.knife"; case .travel: "tram"; case .stay: "bed.double"; case .health: "cross.case"; case .service: "building.2"; case .work: "book"; case .personal: "square.and.pencil" } }
    var detail: String { switch self { case .shopping: "规格、价格、售后"; case .dining: "口味、忌口、取餐信息"; case .travel: "目的地、班次、集合点"; case .stay: "入住、预订、房间需求"; case .health: "预约信息、想问的问题"; case .service: "办理事项、材料、编号"; case .work: "讨论重点、待确认事项"; case .personal: "按自己的习惯准备" } }
    var questionHint: String { switch self { case .shopping: "例如：想确认的规格、价格和退换条件"; case .dining: "例如：忌口、口味、是否需要打包"; case .travel: "例如：在哪里上车、需要什么协助"; case .stay: "例如：入住时间、需要确认的设施"; case .health: "例如：想向医生说明的情况和要问的问题"; case .service: "例如：办理事项、要核对的材料"; case .work: "例如：本次讨论重点和需要确认的时间"; case .personal: "写下想说的话，或每行写一个问题" } }
}

struct EverydaySceneDraft: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: EverydaySceneKind = .personal
    var title = ""
    var place = ""
    var address = ""
    var contact = ""
    var phone = ""
    var reference = ""
    var questions = ""
    var notes = ""
    var updatedAt = Date()
    var displayTitle: String { title.trimmed.isEmpty ? kind.title : title.trimmed }
    var callablePhone: CustomerPhone? { CustomerPhone(universal: phone) }
    var navigationQuery: String { address.trimmed.isEmpty ? place.trimmed : address.trimmed }
    var hasInformation: Bool { [title,place,address,contact,phone,reference,questions,notes].contains { !$0.trimmed.isEmpty } }
    var displaySummary: String {
        [place.trimmed, address.trimmed, reference.trimmed.isEmpty ? "" : "编号：\(reference.trimmed)", questions.trimmed, notes.trimmed]
            .filter { !$0.isEmpty }.joined(separator: "\n")
    }
    var usefulLines: [String] { questions.components(separatedBy: .newlines).map(\.trimmed).filter { !$0.isEmpty } }
}

struct SavedConversationLine: Codable, Equatable, Identifiable {
    let id: UUID
    let speaker: String
    let text: String
    let date: Date
    let transcribed: Bool
}
struct SavedConversation: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var savedAt: Date
    var lines: [SavedConversationLine]
    var searchableText: String { ([title] + lines.map(\.text)).joined(separator: " ") }
}
struct UniversalPreferences: Codable, Equatable {
    var communication: CommunicationPreference = .spokenReply
    var riderScenes = false
    var haptics = true
    var systemSpeechRate: Double = 0.48
}
struct OpeningContact: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var number: String
    var phraseID: String?
}
struct OpeningSettings: Codable, Equatable {
    var automatic = false
    var delay = 2
    var phraseID = "builtin.您好，我需要文字沟通，谢谢。"
    var contacts: [OpeningContact] = []
    func contact(_ raw: String) -> OpeningContact? {
        guard let key = CustomerPhone(universal: raw)?.matchingKey else { return nil }
        return contacts.first { CustomerPhone(universal: $0.number)?.matchingKey == key }
    }
}
extension CustomerPhone {
    var matchingKey: String {
        if number.range(of: "^1[3-9][0-9]{9}$", options: .regularExpression) != nil { return "+86" + number }
        if CustomerPhone(number) != nil, number.hasPrefix("0") { return "+86" + number.dropFirst() }
        if CustomerPhone(number) != nil, number.hasPrefix("400") || number.hasPrefix("800") { return "+86" + number }
        return number
    }
}
struct UniversalData: Codable {
    // Optional so existing 2.0 files decode without losing conversations.
    var openingSettings: OpeningSettings?
    var version = 1
    var preferences = UniversalPreferences()
    var scenes: [EverydaySceneDraft] = []
    var favoriteSceneKinds: [EverydaySceneKind] = []
    var favoritePhraseIDs: [String] = []
    var phraseCategories: [String: String] = [:]
    var conversations: [SavedConversation] = []
}

enum UniversalStoreError: LocalizedError {
    case invalid, incomplete
    var errorDescription: String? {
        switch self {
        case .invalid: "本机资料暂时无法读取，原文件已保留。请重新读取后再试。"
        case .incomplete: "先填写一点要带去沟通的信息。"
        }
    }
}

@MainActor
final class UniversalStore: ObservableObject {
    @Published private(set) var data = UniversalData()
    @Published private(set) var error: String?
    private(set) var loadFailed = false
    let file: URL
    nonisolated static var defaultFile: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        #if DEBUG && targetEnvironment(simulator)
        if CommandLine.arguments.contains("--test-universal") { return base.appendingPathComponent("UniversalReview/data.json") }
        #endif
        return base.appendingPathComponent("UniversalLife/data.json")
    }
    init(file: URL = UniversalStore.defaultFile) {
        self.file = file
        #if DEBUG && targetEnvironment(simulator)
        if CommandLine.arguments.contains("--test-universal"), CommandLine.arguments.contains("--reset-universal") { try? FileManager.default.removeItem(at: file) }
        #endif
        reload()
    }
    func reload() {
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                let value = try JSONDecoder().decode(UniversalData.self, from: Data(contentsOf: file))
                guard value.version == 1, Set(value.scenes.map(\.id)).count == value.scenes.count,
                      Set(value.conversations.map(\.id)).count == value.conversations.count,
                      value.preferences.systemSpeechRate.isFinite, (0.35...0.6).contains(value.preferences.systemSpeechRate) else { throw UniversalStoreError.invalid }
                data = value
            } else { data = UniversalData() }
            loadFailed = false; error = nil
        } catch { loadFailed = true; self.error = UniversalStoreError.invalid.localizedDescription }
    }
    @discardableResult private func commit(_ update: (inout UniversalData) -> Void) -> Bool {
        guard !loadFailed else { return false }
        var next = data; update(&next)
        do {
            let encoded = try JSONEncoder().encode(next)
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            #if os(iOS)
            try encoded.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            #else
            try encoded.write(to: file, options: .atomic)
            #endif
            data = next; error = nil; return true
        } catch { self.error = "保存失败，原资料已保留。请检查手机空间后重试。"; return false }
    }
    var openings: OpeningSettings { data.openingSettings ?? OpeningSettings() }
    @discardableResult func updateOpenings(_ change: (inout OpeningSettings) -> Void) -> Bool {
        commit { data in
            var settings = data.openingSettings ?? OpeningSettings()
            change(&settings)
            settings.delay = min(8, max(1, settings.delay))
            data.openingSettings = settings
        }
    }
    @discardableResult func updatePreferences(_ update: (inout UniversalPreferences) -> Void) -> Bool {
        commit { value in update(&value.preferences); value.preferences.systemSpeechRate = min(0.6, max(0.35, value.preferences.systemSpeechRate)) }
    }
    @discardableResult func saveScene(_ draft: EverydaySceneDraft) -> Bool {
        guard draft.hasInformation else { error = UniversalStoreError.incomplete.localizedDescription; return false }
        return commit { value in
            var saved = draft; saved.updatedAt = Date()
            value.scenes.removeAll { $0.id == saved.id }; value.scenes.insert(saved, at: 0)
        }
    }
    @discardableResult func deleteScene(_ id: UUID) -> Bool { commit { $0.scenes.removeAll { $0.id == id } } }
    @discardableResult func toggleSceneFavorite(_ kind: EverydaySceneKind) -> Bool {
        commit { value in if value.favoriteSceneKinds.contains(kind) { value.favoriteSceneKinds.removeAll { $0 == kind } } else { value.favoriteSceneKinds.append(kind) } }
    }
    @discardableResult func togglePhraseFavorite(_ id: String) -> Bool {
        commit { value in if value.favoritePhraseIDs.contains(id) { value.favoritePhraseIDs.removeAll { $0 == id } } else { value.favoritePhraseIDs.append(id) } }
    }
    @discardableResult func setCategory(_ category: String, for id: String) -> Bool { commit { $0.phraseCategories[id] = category.trimmed.isEmpty ? nil : String(category.trimmed.prefix(20)) } }
    @discardableResult func saveConversation(id: UUID, title: String, messages: [ConversationMessage]) -> Bool {
        guard !messages.isEmpty else { error = "还没有可以保存的对话。"; return false }
        let saved = SavedConversation(id: id, title: title, savedAt: Date(), lines: messages.map {
            SavedConversationLine(id: $0.id, speaker: $0.speaker == .me ? "我" : "对方", text: $0.text, date: $0.date, transcribed: $0.isTranscribed)
        })
        return commit { $0.conversations.removeAll { $0.id == id }; $0.conversations.insert(saved, at: 0) }
    }
    @discardableResult func deleteConversation(_ id: UUID) -> Bool { commit { $0.conversations.removeAll { $0.id == id } } }
    @discardableResult func clearSavedInformation() -> Bool { commit { $0.scenes = []; $0.conversations = [] } }
}

extension String { var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) } }

// CallKit reports lifecycle and UUID, never the far-end telephone number.
struct ObservedLine: Equatable {
    let id: UUID
    var outgoing: Bool, connected: Bool, ended: Bool, held: Bool
}

struct OpeningWindow {
    var requested: TimeInterval
    var delay: TimeInterval
    var line: UUID?
    var due: TimeInterval?
    var consumed = false
    enum Decision: Equatable { case wait, play, cancel }

    mutating func check(_ calls: [ObservedLine], now: TimeInterval, accepted: Bool, ready: Bool) -> Decision {
        let live = calls.filter { !$0.ended }
        guard calls.allSatisfy({ !$0.ended || $0.id != line }), live.count <= 1 else { return .cancel }
        guard let call = live.first else { return line == nil && now-requested < 15 ? .wait : .cancel }
        guard call.outgoing, !call.held else { return .cancel }
        if line == nil {
            guard now-requested < 15, !call.connected else { return .cancel }
            line = call.id
        }
        guard line == call.id else { return .cancel }
        if consumed { return .wait }
        guard now-requested < 100 else { return .cancel }
        guard call.connected else { return due == nil ? .wait : .cancel }
        if due == nil { due = now + delay }
        guard let due, now <= due + 3 else { return .cancel }
        guard now >= due, accepted, ready else { return .wait }
        consumed = true
        return .play
    }
}

