import SwiftUI

enum TermMatcher {
    static func match(_ text: String, in terms: [Term]) -> Term? {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return nil }

        var best: Term?
        var bestLength = 0

        for term in terms {
            for key in [term.standard, term.colloquial] where key.count >= 2 && source.contains(key) {
                if key.count > bestLength {
                    best = term
                    bestLength = key.count
                }
            }
        }

        return best
    }
}

struct TermHint: View {
    let term: Term?
    let scene: SceneKind

    @Environment(\.colorScheme) private var scheme

    init(term: Term?, scene: SceneKind) {
        self.term = term
        self.scene = scene
    }

    @ViewBuilder
    var body: some View {
        if let term {
            Text(message(for: term))
                .font(YZTheme.font(size: 12, textStyle: .caption, maxSize: 17))
                .foregroundStyle(SceneTheme.primary(scheme))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SceneTheme.soft(scheme))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            YZTheme.highContrast ? Color.black : SceneTheme.softLine(scheme),
                            lineWidth: YZTheme.highContrast ? 1.5 : 1
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityLabel(message(for: term))
        }
    }

    private func message(for term: Term) -> String {
        let who = scene == .medical ? "医生" : "对方"
        return "\(who)可能这样说：\(term.standard) · \(who)常问：\(term.ask)"
    }
}
