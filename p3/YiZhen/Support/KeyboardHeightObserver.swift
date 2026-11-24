import Observation
import UIKit

@MainActor
@Observable
final class KeyboardHeightObserver {
    private(set) var height: CGFloat = 0
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            Task { @MainActor [weak self] in
                self?.update(frame: frame)
            }
        }
    }

    private func update(frame: CGRect) {
        let overlap = max(0, UIScreen.main.bounds.maxY - frame.minY)
        let bottomInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.bottom ?? 0
        height = max(0, overlap - bottomInset)
    }
}

struct ComposerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func composerHeightPreference() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ComposerHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        )
    }
}