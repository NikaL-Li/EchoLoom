import Foundation
import Combine
import CoreLocation

enum YLCTTab: String, CaseIterable, Identifiable {
    case home = "沟通"
    case scenes = "场景"
    case phrases = "常用语"
    case account = "我的"
    var id: String { rawValue }
    var icon: String {
        switch self { case .home: "bubble.left.and.bubble.right.fill"; case .scenes: "square.grid.2x2.fill"; case .phrases: "quote.bubble.fill"; case .account: "person.crop.circle.fill" }
    }
}

enum ServiceMode: String, CaseIterable, Identifiable {
    case deliver = "送餐"
    case pickup = "取餐"
    var id: String { rawValue }
    var icon: String { self == .deliver ? "bicycle" : "bag.fill" }
    var subtitle: String { self == .deliver ? "跟顾客、门卫、保安说" : "跟商家说" }
}

struct AddressDraft {
    var community = ""
    var building = ""
    var room = ""
    var floor = ""
    var phone = ""
    var note = ""

    var summary: String {
        let buildingText = building.isEmpty ? "" : (building.hasSuffix("栋") || building.hasSuffix("楼") ? building : "\(building)栋")
        let roomText = room.isEmpty ? "" : (room.hasSuffix("室") ? room : "\(room)室")
        let floorText = floor.isEmpty ? "" : (floor.hasSuffix("楼") || floor.hasSuffix("层") ? floor : "\(floor)楼")
        return ([community] + [buildingText, roomText, floorText].filter { !$0.isEmpty && !community.contains($0) })
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: " ")
    }
}

struct PickupDraft {
    var merchant = ""
    var address = ""
    var phone = ""
    var code = ""
}

struct ForecastDay: Identifiable, Codable {
    var id: String { name }
    let name: String
    let range: String
    let weather: String
}

struct WeatherState: Codable {
    var reportTime: String?
    var citySource: String?
    var city = ""
    var province = ""
    var temp = "--"
    var text = "暂未获取"
    var humidity = "--"
    var wind = "风况未知"
    var tip = "出行注意安全，记得留出休息时间"
    var isLoaded = false
    var updatedAt: Date?
    var days: [ForecastDay] = []
    var symbol: String {
        if text.contains("雷") { return "cloud.bolt.rain.fill" }
        if text.contains("雪") { return "cloud.snow.fill" }
        if text.contains("雨") { return "cloud.rain.fill" }
        if text.contains("雾") || text.contains("霾") { return "cloud.fog.fill" }
        if text.contains("阴") { return "cloud.fill" }
        if text.contains("云") { return "cloud.sun.fill" }
        return Calendar.current.component(.hour, from: Date()) >= 18 ? "moon.stars.fill" : "sun.max.fill"
    }
}

struct DayRecord: Identifiable {
    var id: String { date }
    let label: String
    let date: String
    let count: Int
}

struct CompletedOrder: Codable, Identifiable {
    let id: UUID
    let completedAt: Date
}

struct OrderSummary {
    let today: Int
    let week: Int
    let month: Int
    let year: Int
    let days: [DayRecord]
}

enum OrderHistory {
    static func summary(_ orders: [CompletedOrder], now: Date = Date(), calendar: Calendar = .current) -> OrderSummary {
        let start = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: start)!
        let monthStart = calendar.dateInterval(of: .month, for: now)!.start
        let yearStart = calendar.dateInterval(of: .year, for: now)!.start
        let valid = orders.filter { $0.completedAt <= now }
        let counts = Dictionary(grouping: valid) { calendar.startOfDay(for: $0.completedAt) }.mapValues(\.count)
        let key = DateFormatter()
        key.calendar = calendar
        key.timeZone = calendar.timeZone
        key.locale = Locale(identifier: "en_US_POSIX")
        key.dateFormat = "yyyy-MM-dd"
        let label = DateFormatter()
        label.calendar = calendar
        label.timeZone = calendar.timeZone
        label.locale = Locale(identifier: "zh_CN")
        label.dateFormat = "M月d日"
        let days = (0..<30).map { offset -> DayRecord in
            let day = calendar.date(byAdding: .day, value: -offset, to: start)!
            return DayRecord(label: offset == 0 ? "今天" : offset == 1 ? "昨天" : label.string(from: day), date: key.string(from: day), count: counts[day, default: 0])
        }
        return OrderSummary(today: counts[start, default: 0],
                            week: valid.filter { $0.completedAt >= weekStart }.count,
                            month: valid.filter { $0.completedAt >= monthStart }.count,
                            year: valid.filter { $0.completedAt >= yearStart }.count, days: days)
    }
}

// Only explicit field markers may populate room/code fields. A phone number is never a room.
enum ScreenshotParser {
    static func match(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let range = result.numberOfRanges > 1 ? result.range(at: 1) : result.range
        guard let swiftRange = Range(range, in: text) else { return nil }
        return String(text[swiftRange])
    }
    static func address(_ text: String) -> AddressDraft {
        var result = AddressDraft()
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        result.phone = match(#"(?<![0-9])1[3-9][0-9]{9}(?![0-9])"#, in: text) ?? ""
        result.floor = match(#"(?<![0-9])([0-9]{1,2})\s*(?:楼(?!栋)|层)"#, in: text) ?? ""
        result.room = match(#"(?<![0-9])([0-9]{2,5})\s*(?:室|房)(?!号)"#, in: text)
            ?? match(#"房号[：:\s]*([A-Za-z]?[0-9]{2,5})(?![0-9])"#, in: text) ?? ""
        result.building = match(#"([A-Za-z0-9一二三四五六七八九十]+)\s*(?:栋|幢|号楼)"#, in: text) ?? ""
        result.community = lines.first(where: { line in
            ["小区", "公寓", "花园", "大厦", "路", "街"].contains(where: line.contains)
        }) ?? ""
        return result
    }
    static func pickup(_ text: String) -> PickupDraft {
        var result = PickupDraft()
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        result.phone = match(#"(?<![0-9])1[3-9][0-9]{9}(?![0-9])"#, in: text)
            ?? match(#"(?:手机尾号|手机号尾号|尾号)[：:\s]*([0-9]{4})(?![0-9])"#, in: text) ?? ""
        result.code = match(#"(?:取餐码|取餐号|取货码)[：:#＃\s]*([A-Za-z0-9-]{1,12})(?![A-Za-z0-9-])"#, in: text) ?? ""
        result.merchant = lines.first { line in ["店", "餐厅", "咖啡", "餐馆"].contains(where: line.contains) } ?? ""
        result.address = lines.first { line in ["路", "街", "巷"].contains(where: line.contains) } ?? ""
        return result
    }
}

struct GeoResponseDTO: Decodable {
    let adcode: String?
    let source: String?
    let ok: Bool?
    let city: String?
    let province: String?
    let weather: WeatherDTO?
}

struct WeatherDTO: Decodable {
    let reportTime: String?
    let temp: String?
    let text: String?
    let humidity: String?
    let wind: String?
    let forecast: [ForecastDTO]?
}

struct ForecastDTO: Decodable {
    let date: String?
    let dayWeather: String?
    let nightWeather: String?
    let dayTemp: String?
    let nightTemp: String?
}

struct UserDTO: Decodable {
    let id: Int
    let phone: String
    let nickname: String?
}

struct LoginResponseDTO: Decodable {
    let user: UserDTO?
    let error: String?
}

struct OCRResponseDTO: Decodable {
    let text: String?
    let engine: String?
}

enum BackendError: LocalizedError {
    case badStatus(Int)
    case decode
    case empty
    case unavailable

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): "服务返回 \(code)"
        case .decode: "返回数据无法解析"
        case .empty: "没有识别到文字，请选择清晰的订单截图"
        case .unavailable: "识别服务暂时不可用，请稍后重试或手动填写"
        }
    }
}

struct BackendClient {
    static let baseURL = ServiceOrigin.url

    static func geo(lat: Double? = nil, lng: Double? = nil) async throws -> GeoResponseDTO {
        var components = URLComponents(url: baseURL.appending(path: "/api/geo"), resolvingAgainstBaseURL: false)!
        if let lat, let lng {
            components.queryItems = [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lng", value: String(lng))
            ]
        }
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: components.url!, timeoutInterval: 10))
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BackendError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(GeoResponseDTO.self, from: data)
    }

    static func login(phone: String, password: String) async throws -> UserDTO {
        var request = URLRequest(url: baseURL.appending(path: "/api/auth/login"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "phone": phone,
            "password": password,
            "remember": true
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.decode }
        if !(200..<300).contains(http.statusCode) {
            let dto = try? JSONDecoder().decode(LoginResponseDTO.self, from: data)
            throw NSError(domain: "YLCT", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: http.statusCode == 429 ? "操作太频繁，请稍后再试" : http.statusCode >= 500 ? "登录服务暂时不可用，请稍后重试" : dto?.error ?? "手机号或密码不正确"
            ])
        }
        let dto = try JSONDecoder().decode(LoginResponseDTO.self, from: data)
        guard let user = dto.user else { throw BackendError.decode }
        return user
    }

    static func currentUser() async throws -> UserDTO? {
        var request = URLRequest(url: baseURL.appending(path: "/api/auth/me"))
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.decode }
        if http.statusCode == 401 { return nil }
        guard (200..<300).contains(http.statusCode) else { throw BackendError.badStatus(http.statusCode) }
        return try JSONDecoder().decode(LoginResponseDTO.self, from: data).user
    }

    static func logout() async throws {
        var request = URLRequest(url: baseURL.appending(path: "/api/auth/logout"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BackendError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        for cookie in HTTPCookieStorage.shared.cookies(for: baseURL) ?? [] { HTTPCookieStorage.shared.deleteCookie(cookie) }
    }

    static func ocr(imageData: Data) async throws -> String {
        var request = URLRequest(url: baseURL.appending(path: "/api/ocr"))
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.decode }
        if http.statusCode == 503 { throw BackendError.unavailable }
        guard (200..<300).contains(http.statusCode) else { throw BackendError.badStatus(http.statusCode) }
        let dto = try JSONDecoder().decode(OCRResponseDTO.self, from: data)
        let text = (dto.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw BackendError.empty }
        return text
    }
}

final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var status = "未请求"

    private var requested = false
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        requested = true
        switch manager.authorizationStatus {
        case .notDetermined: status = "等待授权"; manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation(); status = "定位中"
        default: status = "未授权"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            status = "已授权"
            if requested { manager.requestLocation() }
        case .denied, .restricted:
            requested = false; coordinate = nil; status = "未授权"
        case .notDetermined:
            status = "等待授权"
        @unknown default:
            status = "未知"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard requested else { return }; requested = false
        coordinate = location.coordinate
        status = "已定位"
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        requested = false; status = "定位失败"
    }
}

// Ephemeral conversation state: no disk or cloud history. Audio attempts have their
// own identity so a delayed completion can never complete a newer replay.
enum PlaybackPhase: String {
    case idle, preparing, playing, completed, stopped, failed
    var isBusy: Bool { self == .preparing || self == .playing }
    var label: String {
        switch self {
        case .idle: "尚未播报"
        case .preparing: "正在准备声音"
        case .playing: "正在播报"
        case .completed: "播报结束"
        case .stopped: "已停止 · 可重播"
        case .failed: "未能播报 · 可重试"
        }
    }
}
struct PlaybackSnapshot: Equatable {
    var id: UUID?
    var phase: PlaybackPhase = .idle
    var sourceID: String?
    var elapsed: TimeInterval = 0
    var duration: TimeInterval?
    // System speech reports words, not a reliable total audio duration.
    var spokenFraction: Double?

    var progress: Double {
        if phase == .completed { return 1 }
        guard phase != .idle, phase != .preparing else { return 0 }
        let value: Double
        if let duration, duration.isFinite, duration > 0 {
            value = elapsed / duration
        } else {
            value = spokenFraction ?? 0
        }
        // Only the player's completion callback may mark a sentence finished.
        return value.isFinite ? min(max(value, 0), 0.99) : 0
    }
    var percent: Int { Int((progress * 100).rounded(.down)) }
    var timingLabel: String {
        if phase == .preparing { return "准备好后开始" }
        if let duration, duration.isFinite, duration > 0 {
            return "\(Self.clock(phase == .completed ? ceil(duration) : min(elapsed, duration))) / \(Self.clock(ceil(duration)))"
        }
        if phase == .completed { return "已全部播完" }
        return "系统语音 · 已播 \(Self.clock(elapsed))"
    }
    var accessibilityValue: String { "\(phase.label)，\(timingLabel)" }
    private static func clock(_ time: TimeInterval) -> String {
        let seconds = time.isFinite ? Int(min(max(time, 0), 359999)) : 0
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
// Read by visible progress views only. Sampling never publishes app-wide changes.
@MainActor
final class PlaybackProgressClock {
    private var snapshot = PlaybackSnapshot()
    private var audioPosition: (() -> TimeInterval)?
    private var startedAt: TimeInterval = 0
    private let now: () -> TimeInterval

    init(now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.now = now
    }
    func start(_ snapshot: PlaybackSnapshot, audioPosition: (() -> TimeInterval)? = nil) {
        self.snapshot = snapshot
        self.audioPosition = audioPosition
        startedAt = now()
    }
    func sample(fallback: PlaybackSnapshot) -> PlaybackSnapshot {
        guard let id = fallback.id, id == snapshot.id,
              fallback.phase == .playing, snapshot.phase == .playing else { return fallback }
        if let audioPosition, let duration = snapshot.duration {
            let position = audioPosition()
            if position.isFinite {
                snapshot.elapsed = max(snapshot.elapsed, min(max(position, 0), duration))
            }
        } else {
            snapshot.elapsed = max(snapshot.elapsed, now() - startedAt)
        }
        return snapshot
    }
    func updateSpokenFraction(_ fraction: Double) {
        guard snapshot.phase == .playing, fraction.isFinite else { return }
        snapshot.spokenFraction = max(snapshot.spokenFraction ?? 0, min(max(fraction, 0), 0.99))
    }
    func finish(_ phase: PlaybackPhase, fallback: PlaybackSnapshot) -> PlaybackSnapshot {
        var final = sample(fallback: fallback)
        final.phase = phase
        if phase == .completed, let duration = final.duration { final.elapsed = duration }
        snapshot = final
        audioPosition = nil
        return final
    }
}

enum ConversationSpeechRoute { case system, mimoShortcut }

struct ConversationMessage: Identifiable, Equatable {
    enum Speaker { case other, me }
    let id: UUID
    let speaker: Speaker
    let text: String
    let date: Date
    var isTranscribed = false
    var isTextOnly = false
    var playbackID: UUID?
    var playback: PlaybackPhase = .idle
    var playbackSnapshot = PlaybackSnapshot()
    var shortcutID: String?
    var speechRoute: ConversationSpeechRoute { shortcutID == nil ? .system : .mimoShortcut }
}
struct ConversationLog {
    let sessionID = UUID()
    private(set) var messages: [ConversationMessage] = []
    var draft = ""
    private var committedSegments: Set<UUID> = []

    mutating func receive(_ text: String, segmentID: UUID, typed: Bool = false, now: Date = Date()) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, committedSegments.insert(segmentID).inserted else { return }
        messages.append(ConversationMessage(id: segmentID, speaker: .other, text: clean, date: now, isTranscribed: !typed))
    }
    @discardableResult mutating func send(_ text: String, shortcutID: String? = nil, textOnly: Bool = false, now: Date = Date()) -> UUID? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let id = UUID()
        messages.append(ConversationMessage(id: id, speaker: .me, text: clean, date: now, isTextOnly: textOnly, shortcutID: shortcutID))
        return id
    }
    mutating func beginPlayback(messageID: UUID, attemptID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageID && $0.speaker == .me }) else { return }
        messages[index].playbackID = attemptID
        messages[index].playback = .preparing
        messages[index].playbackSnapshot = PlaybackSnapshot(id: attemptID, phase: .preparing)
    }
    mutating func updatePlayback(_ snapshot: PlaybackSnapshot) {
        guard let id = snapshot.id,
              let index = messages.firstIndex(where: { $0.playbackID == id }),
              messages[index].playback.isBusy else { return }
        messages[index].playback = snapshot.phase
        messages[index].playbackSnapshot = snapshot
    }
    mutating func clear() { self = ConversationLog() }
}

// Explicit user intent plus lifecycle gate. Resuming never depends on a guessed
// audio duration; only the current playback delegate can release the audio turn.
struct ConversationListeningGate {
    var requested = false
    var visible = false
    var foreground = true
    var callActive = false
    var playbackBusy = false
    var canListen: Bool { requested && visible && foreground && !callActive && !playbackBusy }
    mutating func suspend() { requested = false }
}

// Each entrance chooses its own starting mode. A home shortcut cannot change
// the next order's default, and home conversations do not contain order data.
enum DialogueScope: Hashable { case home, delivery, pickup, scene(UUID) }
enum DialogueEntry: Equatable {
    case faceToFace, quickSpeech, delivery, pickup, scene(UUID, phone: Bool)
    var startsFaceToFace: Bool { switch self { case .faceToFace: true; case .scene(_, let phone): !phone; default: false } }
    var scope: DialogueScope {
        switch self { case .faceToFace, .quickSpeech: .home; case .delivery: .delivery; case .pickup: .pickup; case .scene(let id, _): .scene(id) }
    }
    var serviceMode: ServiceMode? {
        switch self { case .delivery: .deliver; case .pickup: .pickup; default: nil }
    }
}

struct CustomerPhone: Equatable {
    let number: String
    init?(_ raw: String) {
        guard raw.rangeOfCharacter(from: .controlCharacters) == nil else { return nil }
        let halfWidth = raw.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? raw
        let allowedFormatting = CharacterSet(charactersIn: " ()-\u{00a0}")
        let clean = halfWidth.unicodeScalars.filter { !allowedFormatting.contains($0) }.map(String.init).joined()
        // Never turn masked numbers, four-digit suffixes, extensions, or URL-like
        // strings into a different callable number by indiscriminately stripping.
        let patterns = ["^1[3-9][0-9]{9}$", "^0[1-9][0-9]{8,10}$", "^(400|800)[0-9]{7}$", "^\\+[1-9][0-9]{7,14}$"]
        guard patterns.contains(where: { clean.range(of: $0, options: .regularExpression) != nil }) else { return nil }
        if clean.hasPrefix("+86") {
            let national = String(clean.dropFirst(3))
            guard national.range(of: "^(1[3-9][0-9]{9}|[1-9][0-9]{9,10}|(400|800)[0-9]{7})$", options: .regularExpression) != nil else { return nil }
        }
        number = clean
    }
    // General address-book dialing accepts intact local numbers too. Do not
    // infer a country or silently strip extensions or short rider suffixes.
    init?(universal raw: String) {
        guard raw.rangeOfCharacter(from: .controlCharacters) == nil else { return nil }
        let half = raw.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? raw
        let formatting = CharacterSet(charactersIn: "().-").union(.whitespaces)
        let clean = half.unicodeScalars.filter { !formatting.contains($0) }.map(String.init).joined()
        if let known = Self(clean) { self = known; return }
        guard clean.range(of: "^[0-9]{7,15}$", options: .regularExpression) != nil else { return nil }
        number = clean
    }
    var url: URL { URL(string: "tel:\(number)")! }
}

extension AddressDraft {
    var navigationQuery: String { community.trimmingCharacters(in: .whitespacesAndNewlines) }
    var customerPhone: CustomerPhone? { CustomerPhone(phone) }
    var confirmationQuestion: String { summary.isEmpty ? "" : "您好，我是听障骑手。请确认送到\(summary)，对吗？" }
    var hasDeliveryContext: Bool { !summary.isEmpty || !phone.isEmpty || !note.isEmpty }
}
enum NavigationTravelMode: String, CaseIterable, Identifiable {
    case cycling, walking, driving
    var id: String { rawValue }
    var label: String { switch self { case .cycling: "骑行"; case .walking: "步行"; case .driving: "驾车" } }
}
struct OrderNavigationLink {
    static func url(for query: String, mode: NavigationTravelMode = .cycling, unified: Bool = true) -> URL? {
        let destination = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else { return nil }
        var components = URLComponents(string: "https://maps.apple.com/")!
        if unified {
            components.path = "/directions"
            components.queryItems = [URLQueryItem(name: "destination", value: destination), URLQueryItem(name: "mode", value: mode.rawValue)]
        } else if mode == .cycling {
            // iOS 18.2/18.3 legacy links lack a documented cycling route flag.
            // Show the destination and let the rider choose cycling in Maps.
            components.queryItems = [URLQueryItem(name: "q", value: destination)]
        } else {
            components.queryItems = [URLQueryItem(name: "daddr", value: destination), URLQueryItem(name: "dirflg", value: mode == .walking ? "w" : "d")]
        }
        // Keep literal plus signs in place names distinct from form-encoded spaces.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }
}
