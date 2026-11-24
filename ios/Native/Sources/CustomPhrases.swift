import Foundation
import Combine
import AVFAudio

struct CustomPhrase: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let audioID: UUID
    let createdAt: Date
}

struct PhraseShortcut: Identifiable {
    let id: String
    let text: String
    let custom: CustomPhrase?
    static func saved(_ phrase: CustomPhrase) -> Self { Self(id: "custom.\(phrase.id.uuidString)", text: phrase.text, custom: phrase) }
    static func builtIn(_ text: String) -> Self { Self(id: "builtin.\(text)", text: text, custom: nil) }
    static let riderTexts = ["餐放门口了，麻烦您取一下", "我在小区门口，马上到", "我拍张照给您确认", "电梯需要刷卡，能帮我按一下吗", "放门口鞋柜上了，谢谢", "我是听障骑手，请用文字沟通"]
    static let faceTexts = ["请再说一遍，慢一点，谢谢。", "请稍等，我正在打字。", "好的，谢谢！", "您好，我需要文字沟通，谢谢。", "请面对我说话，我在看字幕。", "可以打字给我看吗？", "请把重要的信息写下来。", "我想确认一下刚才的信息。", "没关系，我们慢慢说。"]
    static let phoneTexts = faceTexts
    static let allTexts = faceTexts + riderTexts
}

enum PhraseVoice: String, CaseIterable {
    case female, male
    var name: String { self == .female ? "冰糖" : "苏打" }
    var label: String { self == .female ? "女声" : "男声" }
}

// Every fixed built-in reply ships with both MiMo voices. Runtime playback must
// never generate or download these files, including on a fresh offline install.
enum BundledReplyAudio {
    static let files: [String: String] = [
        "餐放门口了，麻烦您取一下": "preset_door",
        "我在小区门口，马上到": "preset_gate",
        "我拍张照给您确认": "preset_photo",
        "电梯需要刷卡，能帮我按一下吗": "preset_elevator",
        "放门口鞋柜上了，谢谢": "preset_shoe",
        "我是听障骑手，请用文字沟通": "preset_deaf",
        "我是听障骑手，请用文字和我沟通，谢谢。": "preset_sign",
        "请再说一遍，慢一点，谢谢。": "preset_face_repeat",
        "请稍等，我正在打字。": "preset_face_wait",
        "好的，谢谢！": "preset_face_thanks",
        "您好，我需要文字沟通，谢谢。": "preset_general_intro",
        "请面对我说话，我在看字幕。": "preset_general_caption",
        "可以打字给我看吗？": "preset_general_type",
        "请把重要的信息写下来。": "preset_general_write",
        "我想确认一下刚才的信息。": "preset_general_confirm",
        "没关系，我们慢慢说。": "preset_general_patience"
    ]
    static func resourceName(text: String, voice: PhraseVoice) -> String? {
        files[text].map { "\($0)_\(voice == .male ? "m" : "f")" }
    }
}

enum CustomPhraseError: LocalizedError {
    case missing, empty, tooLong, duplicate, invalidAudio, mimoUnavailable, unreadableLibrary, invalidOrder, unreadableOrder
    var errorDescription: String? {
        switch self {
        case .missing: "这条常用语已被移除，请重新添加。"
        case .empty: "先写一句经常需要说的话。"
        case .tooLong: "常用语最多 200 个字，请拆成两句保存。"
        case .duplicate: "这句话已经在我的常用语里了。"
        case .invalidAudio: "收到的语音文件无法播放，请重试。"
        case .mimoUnavailable: "MiMo 暂时未能生成指定声音，请稍后重试。"
        case .unreadableLibrary: "本机常用语暂时无法读取，原文件已保留。请重新打开 App 后再试。"
        case .invalidOrder: "常用语发生了变化，请重新打开排序后再试。"
        case .unreadableOrder: "已保存的顺序暂时无法读取，原文件已保留。请重试。"
        }
    }
}

// A manifest is committed only after both validated voice files exist. Replacing
// a phrase uses a new audio directory so failures cannot destroy an older pair.
struct CustomPhraseStore {
    let root: URL
    private var manifest: URL { root.appendingPathComponent("phrases.json") }
    private var orderFile: URL { root.appendingPathComponent("order.json") }
    static var defaultRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        #if DEBUG && targetEnvironment(simulator)
        if CommandLine.arguments.contains("--test-custom-phrases") { return base.appendingPathComponent("CustomPhrases-UIReview", isDirectory: true) }
        #endif
        return base.appendingPathComponent("CustomPhrases", isDirectory: true)
    }
    static func cleaned(_ text: String) throws -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CustomPhraseError.empty }
        guard text.count <= 200 else { throw CustomPhraseError.tooLong }
        return text
    }
    func load() throws -> [CustomPhrase] {
        guard FileManager.default.fileExists(atPath: manifest.path) else { return [] }
        do {
            let phrases = try JSONDecoder().decode([CustomPhrase].self, from: Data(contentsOf: manifest))
            guard Set(phrases.map(\.id)).count == phrases.count else { throw CustomPhraseError.unreadableLibrary }
            return phrases
        } catch { throw CustomPhraseError.unreadableLibrary }
    }
    func audioURL(for phrase: CustomPhrase, voice: PhraseVoice) -> URL {
        root.appendingPathComponent(phrase.audioID.uuidString, isDirectory: true).appendingPathComponent(voice.rawValue + ".wav")
    }
    func isReady(_ phrase: CustomPhrase) -> Bool {
        PhraseVoice.allCases.allSatisfy { voice in
            let url = audioURL(for: phrase, voice: voice)
            return ((try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])).map { $0.isRegularFile == true && ($0.fileSize ?? 0) > 44 }) ?? false
        }
    }
    static func validateAudio(_ data: Data) throws {
        guard data.count > 44, data.count < 15_000_000,
              data.prefix(4) == Data("RIFF".utf8), data.dropFirst(8).prefix(4) == Data("WAVE".utf8) else { throw CustomPhraseError.invalidAudio }
        let audio = try AVAudioPlayer(data: data)
        guard audio.duration.isFinite, audio.duration > 0 else { throw CustomPhraseError.invalidAudio }
    }
    @discardableResult func save(text: String, female: Data, male: Data, replacing id: UUID? = nil) throws -> CustomPhrase {
        let clean = try Self.cleaned(text)
        var phrases = try load()
        guard !phrases.contains(where: { $0.id != id && $0.text == clean }) else { throw CustomPhraseError.duplicate }
        try Self.validateAudio(female); try Self.validateAudio(male)
        let old = id.flatMap { id in phrases.first(where: { $0.id == id }) }
        if id != nil && old == nil { throw CustomPhraseError.missing }
        let phrase = CustomPhrase(id: old?.id ?? UUID(), text: clean, audioID: UUID(), createdAt: old?.createdAt ?? Date())
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let directory = root.appendingPathComponent(phrase.audioID.uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try female.write(to: audioURL(for: phrase, voice: .female), options: .atomic)
            try male.write(to: audioURL(for: phrase, voice: .male), options: .atomic)
            if let index = phrases.firstIndex(where: { $0.id == phrase.id }) { phrases[index] = phrase }
            else { phrases.append(phrase) }
            try JSONEncoder().encode(phrases).write(to: manifest, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
        if let old { try? FileManager.default.removeItem(at: root.appendingPathComponent(old.audioID.uuidString, isDirectory: true)) }
        return phrase
    }
    func delete(_ phrase: CustomPhrase) throws {
        let existing = try load()
        guard let current = existing.first(where: { $0.id == phrase.id }) else { return }
        let phrases = existing.filter { $0.id != current.id }
        try JSONEncoder().encode(phrases).write(to: manifest, options: .atomic)
        try? FileManager.default.removeItem(at: root.appendingPathComponent(current.audioID.uuidString, isDirectory: true))
    }

    func loadOrder() throws -> [String] {
        guard FileManager.default.fileExists(atPath: orderFile.path) else { return [] }
        do {
            let ids = try JSONDecoder().decode([String].self, from: Data(contentsOf: orderFile))
            guard Set(ids).count == ids.count else { throw CustomPhraseError.unreadableOrder }
            return ids
        } catch { throw CustomPhraseError.unreadableOrder }
    }

    // Store only stable identities. Reordering never touches or regenerates audio.
    func saveOrder(_ ids: [String], expected: [String]) throws {
        guard ids.count == expected.count, Set(ids).count == ids.count, Set(ids) == Set(expected) else { throw CustomPhraseError.invalidOrder }
        _ = try loadOrder() // Preserve an unreadable existing file instead of overwriting it.
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try JSONEncoder().encode(ids).write(to: orderFile, options: .atomic)
    }
}

enum MiMoPhraseAudio {
    static func fetch(text: String, voice: PhraseVoice) async throws -> Data {
        #if DEBUG && targetEnvironment(simulator)
        if let index = CommandLine.arguments.firstIndex(of: "--test-custom-phrases"), CommandLine.arguments.indices.contains(index + 1) {
            let mode = CommandLine.arguments[index + 1]
            if mode == "offline" || (mode == "male-failure" && voice == .male) { throw URLError(.notConnectedToInternet) }
            if mode == "success" || mode == "male-failure" {
                try await Task.sleep(for: .milliseconds(300))
                let file = voice == .female ? "preset_gate_f" : "preset_gate_m"
                guard let url = Bundle.main.url(forResource: file, withExtension: "wav") else { throw CustomPhraseError.invalidAudio }
                return try Data(contentsOf: url)
            }
        }
        #endif
        var url = URLComponents(url: ServiceOrigin.url.appending(path: "api/tts"), resolvingAgainstBaseURL: false)!
        url.queryItems = [URLQueryItem(name: "text", value: text), URLQueryItem(name: "voice", value: voice.name)]
        var request = URLRequest(url: url.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        request.setValue("audio/wav", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // This existing backend returns MiMo as WAV and its Edge fallback as MP3.
        // Do not silently store a substitute voice under a MiMo voice name.
        guard ["audio/wav", "audio/x-wav", "audio/wave"].contains(http.mimeType?.lowercased() ?? "") else { throw CustomPhraseError.mimoUnavailable }
        try CustomPhraseStore.validateAudio(data)
        return data
    }
}

@MainActor
final class CustomPhraseLibrary: ObservableObject {
    @Published private(set) var phrases: [CustomPhrase] = []
    @Published private(set) var loadError: String?
    @Published private(set) var orderError: String?
    @Published private(set) var shortcutOrder: [String] = []
    @Published private(set) var isGenerating = false
    @Published private(set) var progress = ""
    @Published private(set) var generationError: String?
    @Published private(set) var femaleReady = false
    @Published private(set) var maleReady = false
    let store: CustomPhraseStore
    private let synthesize: (String, PhraseVoice) async throws -> Data
    private var task: Task<Void, Never>?
    private var generation: UUID?
    private var preparedText = ""
    private var prepared: [PhraseVoice: Data] = [:]

    init(root: URL = CustomPhraseStore.defaultRoot, synthesize: @escaping (String, PhraseVoice) async throws -> Data = { try await MiMoPhraseAudio.fetch(text: $0, voice: $1) }) {
        self.synthesize = synthesize
        store = CustomPhraseStore(root: root)
        #if DEBUG && targetEnvironment(simulator)
        if CommandLine.arguments.contains("--test-custom-phrases"), CommandLine.arguments.contains("--reset-test-custom-phrases") {
            try? FileManager.default.removeItem(at: root)
        }
        #endif
        reload()
    }
    func reload() {
        do { phrases = try store.load(); loadError = nil }
        catch { loadError = error.localizedDescription }
        do { shortcutOrder = try store.loadOrder(); orderError = nil; sortSavedPhrases() }
        catch { orderError = error.localizedDescription }
    }
    private func ordered(_ shortcuts: [PhraseShortcut]) -> [PhraseShortcut] {
        let positions = Dictionary(uniqueKeysWithValues: shortcutOrder.enumerated().map { ($0.element, $0.offset) })
        return shortcuts.enumerated().sorted {
            let left = positions[$0.element.id] ?? Int.max
            let right = positions[$1.element.id] ?? Int.max
            return left == right ? $0.offset < $1.offset : left < right
        }.map(\.element)
    }
    private func sortSavedPhrases() { phrases = ordered(phrases.map(PhraseShortcut.saved)).compactMap(\.custom) }
    func shortcuts(including builtIns: [String]) -> [PhraseShortcut] {
        // A user's saved version takes precedence over the same built-in text.
        let customTexts = Set(phrases.map(\.text))
        return ordered(phrases.map(PhraseShortcut.saved) + builtIns.enumerated().filter { !customTexts.contains($0.element) && !builtIns.prefix($0.offset).contains($0.element) }.map { PhraseShortcut.builtIn($0.element) })
    }
    var sortableShortcuts: [PhraseShortcut] {
        // Include hidden duplicate built-ins so edits/deletes cannot lose their position.
        ordered(phrases.map(PhraseShortcut.saved) + PhraseShortcut.allTexts.map(PhraseShortcut.builtIn))
    }
    @discardableResult func reorder(_ ids: [String]) -> Bool {
        guard loadError == nil else { orderError = "请先重新读取常用语，再调整顺序。"; return false }
        do {
            try store.saveOrder(ids, expected: sortableShortcuts.map(\.id))
            shortcutOrder = ids; sortSavedPhrases(); orderError = nil
            return true
        } catch {
            orderError = "顺序未保存，仍保留原顺序。\(error.localizedDescription)"
            return false
        }
    }
    func ready(_ phrase: CustomPhrase) -> Bool { store.isReady(phrase) }
    func phrase(matching text: String) -> CustomPhrase? { phrases.first { $0.text == text.trimmingCharacters(in: .whitespacesAndNewlines) } }
    func audioURL(_ phrase: CustomPhrase, gender: String) -> URL { store.audioURL(for: phrase, voice: PhraseVoice(rawValue: gender) ?? .female) }
    func delete(_ phrase: CustomPhrase) {
        do { try store.delete(phrase); reload() } catch { loadError = "删除失败，原常用语已保留，请重试。" }
    }
    func prepareEditor() {
        cancelGeneration(); generationError = nil; progress = ""; preparedText = ""; prepared = [:]; femaleReady = false; maleReady = false
    }
    func editorTextChanged(_ text: String) {
        guard !isGenerating, text.trimmingCharacters(in: .whitespacesAndNewlines) != preparedText else { return }
        prepared = [:]; preparedText = ""; femaleReady = false; maleReady = false; generationError = nil; progress = ""
    }
    func cancelGeneration() {
        let wasGenerating = isGenerating
        task?.cancel(); task = nil; generation = nil; isGenerating = false
        if wasGenerating { progress = "已取消，尚未保存" }
    }
    func generate(text: String, replacing id: UUID? = nil, onSaved: @escaping () -> Void) {
        guard !isGenerating, loadError == nil else { return }
        let clean: String
        do {
            clean = try CustomPhraseStore.cleaned(text)
            guard !phrases.contains(where: { $0.id != id && $0.text == clean }) else { throw CustomPhraseError.duplicate }
        } catch { generationError = error.localizedDescription; return }
        if clean != preparedText { preparedText = clean; prepared = [:] }
        femaleReady = prepared[.female] != nil; maleReady = prepared[.male] != nil
        generationError = nil; isGenerating = true
        let token = UUID(); generation = token
        task = Task { [weak self] in
            guard let self, self.generation == token, !Task.isCancelled else { return }
            defer { if self.generation == token { self.isGenerating = false; self.task = nil } }
            do {
                for voice in PhraseVoice.allCases where self.prepared[voice] == nil {
                    self.progress = "正在生成\(voice.label) · \(voice.name)…"
                    let data = try await self.synthesize(clean, voice)
                    try Task.checkCancellation()
                    guard self.generation == token else { return }
                    self.prepared[voice] = data
                    self.femaleReady = self.prepared[.female] != nil; self.maleReady = self.prepared[.male] != nil
                }
                try Task.checkCancellation()
                guard self.generation == token, let female = self.prepared[.female], let male = self.prepared[.male] else { return }
                self.progress = "正在保存到本机…"
                try self.store.save(text: clean, female: female, male: male, replacing: id)
                self.reload(); self.prepared = [:]; self.progress = "两种声音已保存，可离线使用"
                self.isGenerating = false
                onSaved()
            } catch is CancellationError { return }
            catch {
                guard self.generation == token, !Task.isCancelled else { return }
                self.generationError = (error as? CustomPhraseError)?.errorDescription ?? "生成或保存失败，请检查网络和手机空间后重试。已生成的声音会保留到退出此页。"
                self.progress = "尚未保存"
            }
        }
    }
}
