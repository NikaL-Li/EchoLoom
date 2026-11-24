import Foundation
import Observation

@MainActor
@Observable
final class DialogViewModel {
    private(set) var revealedMessageIDs: Set<YZMessage.ID> = []
    private(set) var isComposerPresented: Bool
    var draft: String
    private(set) var isSubmitting: Bool = false
    private(set) var pendingScrollMessageID: YZMessage.ID?

    init(isComposerPresented: Bool = false, draft: String = "") {
        self.isComposerPresented = isComposerPresented
        self.draft = draft
    }

    var canSend: Bool {
        !isSubmitting && YZComposerRules.isSendable(draft)
    }

    func reveal(_ id: YZMessage.ID) {
        revealedMessageIDs.insert(id)
    }

    func resetReveals() {
        revealedMessageIDs.removeAll()
    }

    func openComposer() {
        guard !isComposerPresented else { return }
        draft = ""
        isComposerPresented = true
    }

    func closeComposer() {
        isComposerPresented = false
        draft = ""
    }

    @discardableResult
    func submit(state: YZAppState) -> YZMessage.ID? {
        guard !isSubmitting, YZComposerRules.isSendable(draft) else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        guard let id = state.sendMineText(draft) else { return nil }
        draft = ""
        pendingScrollMessageID = id
        return id
    }

    func consumePendingScroll() {
        pendingScrollMessageID = nil
    }
}