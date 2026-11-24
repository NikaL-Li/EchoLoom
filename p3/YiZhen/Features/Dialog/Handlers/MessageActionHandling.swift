import Foundation

@MainActor
protocol MessageActionHandling: AnyObject {
    func replay(_ message: YZMessage)
    func copy(_ message: YZMessage)
    func openCard(_ message: YZMessage)
}

@MainActor
final class PlaceholderMessageActionHandler: MessageActionHandling {
    private let toast: ToastPresenting

    init(toast: ToastPresenting) {
        self.toast = toast
    }

    func replay(_ message: YZMessage) {
        toast.show(YZToast(id: "replay.\(message.id)", message: "播报功能筹备中"))
    }

    func copy(_ message: YZMessage) {
        toast.show(YZToast(id: "copy.\(message.id)", message: "复制功能筹备中"))
    }

    func openCard(_ message: YZMessage) {
        toast.show(YZToast(id: "card.\(message.id)", message: "全屏大字牌筹备中"))
    }
}