import Foundation
import UIKit
import ImageIO
import Combine
import CoreLocation
import CryptoKit
import Network

struct CityPhotoCredit: Decodable {
    let id, title, author, license, licenseURL, source, portraitSHA256, landscapeSHA256: String
}

struct CityPhoto {
    let credit: CityPhotoCredit
    let portrait, landscape: URL
    var key: URL { portrait }

    static let bundled: [Self] = {
        guard let index = Bundle.main.url(forResource: "qingdao-offline", withExtension: "json"),
              let data = try? Data(contentsOf: index),
              let rows = try? JSONDecoder().decode([CityPhotoCredit].self, from: data) else { return [] }
        return rows.compactMap { row in
            guard let p = Bundle.main.url(forResource: row.id + "-portrait", withExtension: "jpg"),
                  let l = Bundle.main.url(forResource: row.id + "-landscape", withExtension: "jpg") else { return nil }
            return Self(credit: row, portrait: p, landscape: l)
        }
    }()
}

enum CityAlbum {
    static let names = ["青岛":"qingdao", "济南":"jinan", "上海":"shanghai", "北京":"beijing"]
    static func city(_ raw: String, adcode: String?) -> String? {
        if let adcode, adcode.count == 6, adcode.allSatisfy(\.isNumber) {
            switch (String(adcode.prefix(2)), String(adcode.prefix(4))) {
            case ("11", _): return "beijing"
            case ("31", _): return "shanghai"
            case (_, "3702"): return "qingdao"
            case (_, "3701"): return "jinan"
            default: return nil
            }
        }
        var city = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if city.last == "市" { city.removeLast() }
        return names[city]
    }
    // Albums roll over at 04:00 China Standard Time, regardless of device timezone.
    static func day(_ date: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let c = cal.dateComponents([.year, .month, .day], from: date.addingTimeInterval(-4 * 3600))
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    static func nextRefresh() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        return cal.nextDate(after: Date(), matching: DateComponents(hour: 4, minute: 0, second: 0), matchingPolicy: .nextTime)!
    }
}

private actor HomePhotoCache {
    struct Manifest: Decodable { let city, day: String; let images: [CityPhotoCredit] }
    private let disk = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("CityAlbums-v2")
    private func fetch(_ url: URL, maxBytes: Int) async throws -> Data {
        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= maxBytes else { throw BackendError.decode }
        return data
    }
    private func check(_ data: Data, hash: String, portrait: Bool) -> Bool {
        guard data.count < 5_000_000, SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == hash,
              let src = CGImageSourceCreateWithData(data as CFData, nil),
              let info = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString:Any],
              info[kCGImagePropertyPixelWidth] as? Int == (portrait ? 1242 : 1440),
              info[kCGImagePropertyPixelHeight] as? Int == (portrait ? 2688 : 810) else { return false }
        return true
    }
    private func file(_ base: URL, directory: URL, row: CityPhotoCredit, portrait: Bool) async throws -> URL {
        let hash = portrait ? row.portraitSHA256 : row.landscapeSHA256
        let name = row.id + (portrait ? "-portrait.jpg" : "-landscape.jpg")
        let local = directory.appendingPathComponent(name)
        if let cached = try? Data(contentsOf: local), check(cached, hash: hash, portrait: portrait) { return local }
        let bytes = try await fetch(base.appendingPathComponent(name), maxBytes: 5_000_000)
        guard check(bytes, hash: hash, portrait: portrait) else { throw BackendError.decode }
        try Task.checkCancellation()
        try bytes.write(to: local, options: .atomic)
        return local
    }
    func album(city: String, day: String) async throws -> [CityPhoto] {
        let base = BackendClient.baseURL.appending(path: "wallpapers/v2/\(day)/\(city)")
        let data = try await fetch(base.appending(path: "index.json"), maxBytes: 100_000)
        let m = try JSONDecoder().decode(Manifest.self, from: data)
        guard m.city == city, m.day == day, m.images.count == 5, Set(m.images.map(\.id)).count == 5,
              m.images.allSatisfy({ $0.id.range(of: "^[A-Za-z0-9_-]{1,80}$", options: .regularExpression) != nil }) else { throw BackendError.decode }
        let dir = disk.appending(path: day).appending(path: city)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var output: [CityPhoto] = []
        for row in m.images {
            try Task.checkCancellation()
            async let p = file(base, directory: dir, row: row, portrait: true)
            async let l = file(base, directory: dir, row: row, portrait: false)
            output.append(try await CityPhoto(credit: row, portrait: p, landscape: l))
        }
        try Task.checkCancellation()
        for folder in (try? FileManager.default.contentsOfDirectory(at: disk, includingPropertiesForKeys: nil)) ?? [] where folder.lastPathComponent < day {
            try? FileManager.default.removeItem(at: folder)
        }
        return output
    }
}

@MainActor
final class HomeOutdoors: ObservableObject {
    @Published private(set) var weather = WeatherState()
    @Published private(set) var loading = false
    @Published private(set) var failed = false
    @Published private(set) var photos = CityPhoto.bundled
    @Published private(set) var photoPlace = "青岛"
    let location = LocationProvider()
    private let cache = HomePhotoCache(), network = NWPathMonitor()
    private let weatherKey = "ylct.home.lastWeather"
    private var usesPhotos = UserDefaults.standard.object(forKey: "home.landscape.photos") as? Bool ?? true
    private var reachable: Bool?, resolvedCity: String?, key: String?, loadedKey: String?
    private var photoJob: Task<Void,Never>?
    private var refreshed: Date?, followUp = false
    private var subscription: AnyCancellable?
    init() {
        if let data = UserDefaults.standard.data(forKey: weatherKey), let saved = try? JSONDecoder().decode(WeatherState.self, from: data) { weather = saved }
        subscription = location.$coordinate.dropFirst().sink { [weak self] _ in
            Task { @MainActor in await self?.refresh(force: true) }
        }
        network.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                guard let self, self.reachable != online else { return }
                let wasOffline = self.reachable == false
                self.reachable = online
                if !online { self.resolvedCity = nil; self.fallback() }
                else if wasOffline { await self.refresh(force: true) }
                else { self.requestPhotos() }
            }
        }
        network.start(queue: DispatchQueue(label:"ylct.wallpaper.network"))
    }
    deinit { network.cancel(); photoJob?.cancel() }
    func refresh(force: Bool = false) async {
        if let key, !key.hasPrefix(CityAlbum.day() + "/") { fallback() }
        if loading { if force { followUp = true }; return }
        guard force || refreshed.map({ Date().timeIntervalSince($0) > 900 }) != false else { requestPhotos(); return }
        loading = true
        defer { loading = false; if followUp { followUp = false; Task { await refresh(force: true) } } }
        let coordinate = location.coordinate
        do {
            let dto = try await BackendClient.geo(lat: coordinate?.latitude, lng: coordinate?.longitude)
            try Task.checkCancellation()
            resolvedCity = dto.ok == true && dto.source == "amap" ? CityAlbum.city(dto.city ?? "", adcode: dto.adcode) : nil
            requestPhotos()
            guard dto.ok == true, let w = dto.weather, let city = dto.city, !city.isEmpty,
                  let temp = w.temp, Double(temp) != nil else { throw BackendError.unavailable }
            var next = WeatherState()
            next.city = city; next.temp = temp; next.text = w.text ?? "天气"; next.humidity = w.humidity ?? "--"; next.wind = w.wind ?? "--"
            next.isLoaded = true; next.updatedAt = Date(); next.reportTime = w.reportTime
            next.citySource = coordinate != nil && dto.source == "amap" ? "按大致位置查询" : "网络参考城市"
            next.days = (w.forecast ?? []).prefix(3).enumerated().map { i, f in
                ForecastDay(name: f.date.map { String($0.suffix(5)) } ?? "第\(i+1)天", range: "\(f.nightTemp ?? "–")～\(f.dayTemp ?? "–")°", weather: f.dayWeather ?? "—")
            }
            weather = next; failed = false; refreshed = Date()
            if let data = try? JSONEncoder().encode(next) { UserDefaults.standard.set(data, forKey: weatherKey) }
        } catch {
            if Task.isCancelled { return }
            resolvedCity = nil; fallback()
            failed = true; refreshed = Date().addingTimeInterval(-840)
        }
    }
    func setPhotosEnabled(_ enabled: Bool) { usesPhotos = enabled; requestPhotos() }
    private func fallback() {
        photoJob?.cancel(); photoJob = nil; key = nil
        if loadedKey != nil { photos = CityPhoto.bundled; photoPlace = "青岛"; loadedKey = nil }
    }
    private func requestPhotos() {
        guard usesPhotos, reachable == true, let city = resolvedCity else { fallback(); return }
        let day = CityAlbum.day(), wanted = day + "/" + city
        if loadedKey == wanted || (key == wanted && photoJob != nil) { return }
        fallback(); key = wanted
        photoJob = Task {
            defer { if !Task.isCancelled { photoJob = nil } }
            guard let items = try? await cache.album(city: city, day: day), !Task.isCancelled,
                  key == wanted, day == CityAlbum.day(), reachable == true else { return }
            photos = items; photoPlace = CityAlbum.names.first(where: { $0.value == city })!.key
            loadedKey = wanted
        }
    }
}
