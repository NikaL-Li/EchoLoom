import SwiftUI
import UIKit
import Observation

struct YZToast: Identifiable, Equatable {
    let id: String
    let message: String
    var duration: TimeInterval = 1.6
}

@MainActor
protocol ToastPresenting {
    func show(_ toast: YZToast)
}

@MainActor
@Observable
final class ToastCenter: ToastPresenting {
    private(set) var current: YZToast?
    private var dismissTask: Task<Void, Never>?

    func show(_ toast: YZToast) {
        current = toast
        dismissTask?.cancel()
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(toast.duration))
            guard let self, !Task.isCancelled, self.current?.id == toast.id else { return }
            withAnimation(self.toastAnimation) {
                self.current = nil
            }
            self.dismissTask = nil
        }
        UIAccessibility.post(notification: .announcement, argument: toast.message)
    }

    func cancel() {
        dismissTask?.cancel()
        dismissTask = nil
        current = nil
    }

    private var toastAnimation: Animation? {
        .easeOut(duration: 0.18)
    }
}