import Foundation

@MainActor
protocol DialogActionHandling: AnyObject {
    func close()
    func faceToFace()
    func listen()
    func speak()
    func fullScreen()
}

@MainActor
final class PlaceholderDialogActionHandler: DialogActionHandling {
    private let toast: ToastPresenting

    init(toast: ToastPresenting) {
        self.toast = toast
    }

    func close() {
        toast.show(YZToast(id: "close", message: "返回"))
    }

    func faceToFace() {
        toast.show(YZToast(id: "faceToFace", message: "面对面模式筹备中"))
    }

    func listen() {
        toast.show(YZToast(id: "listen", message: "听写功能筹备中"))
    }

    func speak() {

    }

    func fullScreen() {
        toast.show(YZToast(id: "fullScreen", message: "全屏功能筹备中"))
    }
}