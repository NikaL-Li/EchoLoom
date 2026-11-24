import Foundation

enum ServiceOrigin {
    static let url: URL = {
        #if WALLPAPER_INTEGRATION && DEBUG && targetEnvironment(simulator)
        return URL(string: "http://localhost:18746")!
        #else
        if let raw = Bundle.main.object(forInfoDictionaryKey: "YSServiceOrigin") as? String,
           let url = URL(string: raw), url.scheme == "https", url.host != nil {
            return url
        }
        return URL(string: "https://ylct.lzc2006.cn")!
        #endif
    }()
}
