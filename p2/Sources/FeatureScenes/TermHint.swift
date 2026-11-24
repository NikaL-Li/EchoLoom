import SwiftUI

public enum TermMatcher {
    public static func match(_ text: String, in terms: [Term]) -> Term? {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return nil }

        var best: Term?
        var bestLength = 0

        for term in terms {
            let keys = [term.standard, term.colloquial]
            for key in keys where key.count >= 2 && source.contains(key) {
                if key.count > bestLength {
                    best = term
                    bestLength = key.count
                }
            }
        }

        return best
    }
}

public struct TermHint: View {
    public let term: Term?
    public let scene: SceneKind

    @Environment(\.colorScheme) private var scheme

    public init(term: Term?, scene: SceneKind) {
        self.term = term
        self.scene = scene
    }

    @ViewBuilder
    public var body: some View {
        if let term {
            Text(message(for: term))
                .font(.system(size: 12))
                .foregroundStyle(SceneTheme.primary(scheme))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SceneTheme.soft(scheme))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(SceneTheme.softLine(scheme), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel(message(for: term))
        }
    }

    private func message(for term: Term) -> String {
        let who = scene == .medical ? "医生" : "对方"
        return "\(who)可能这样说：\(term.standard) · \(who)常问：\(term.ask)"
    }
}