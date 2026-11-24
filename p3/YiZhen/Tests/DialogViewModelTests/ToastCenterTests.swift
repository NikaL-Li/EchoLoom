import XCTest
@testable import YiZhen

@MainActor
final class ToastCenterTests: XCTestCase {
    func testDuplicateKeyKeepsSingleToastAndRestartsTimer() {
        let center = ToastCenter()
        center.show(YZToast(id: "listen", message: "听写功能筹备中"))
        center.show(YZToast(id: "listen", message: "听写功能筹备中"))
        XCTAssertEqual(center.current?.id ?? "", "listen")
        XCTAssertEqual(center.current?.message ?? "", "听写功能筹备中")
        center.cancel()
    }

    func testDifferentKeysReplaceCurrentToast() {
        let center = ToastCenter()
        center.show(YZToast(id: "listen", message: "听写功能筹备中"))
        center.show(YZToast(id: "speak", message: "抽屉已打开"))
        XCTAssertEqual(center.current?.id ?? "", "speak")
        XCTAssertEqual(center.current?.message ?? "", "抽屉已打开")
        center.cancel()
    }

    func testCancelClearsCurrentToast() {
        let center = ToastCenter()
        center.show(YZToast(id: "close", message: "返回"))
        center.cancel()
        XCTAssertNil(center.current)
    }

    func testToastDefaultsToOnePointSixSeconds() {
        let toast = YZToast(id: "fullScreen", message: "全屏功能筹备中")
        XCTAssertEqual(toast.duration, 1.6, accuracy: 0.0001)
    }

    func testTenRapidTapsKeepSingleToast() {
        let center = ToastCenter()
        for _ in 0..<10 {
            center.show(YZToast(id: "listen", message: "听写功能筹备中"))
        }
        XCTAssertEqual(center.current?.id ?? "", "listen")
        center.cancel()
    }
}

@MainActor
final class MessageActionHandlerTests: XCTestCase {
    private func makeHandler() -> (ToastCenter, PlaceholderMessageActionHandler) {
        let center = ToastCenter()
        return (center, PlaceholderMessageActionHandler(toast: center))
    }

    func testOpenCardToastContract() {
        let (center, handler) = makeHandler()
        let message = YZMockData.threeMessages[0]

        handler.openCard(message)

        XCTAssertEqual(center.current?.id ?? "", "card.other.1")
        XCTAssertEqual(center.current?.message ?? "", "全屏大字牌筹备中")
        center.cancel()
    }

    func testActionToastIdsAreDistinct() {
        let (center, handler) = makeHandler()
        let message = YZMockData.threeMessages[0]

        handler.openCard(message)
        XCTAssertEqual(center.current?.id ?? "", "card.other.1")

        handler.replay(message)
        XCTAssertEqual(center.current?.id ?? "", "replay.other.1")
        XCTAssertEqual(center.current?.message ?? "", "播报功能筹备中")

        handler.copy(message)
        XCTAssertEqual(center.current?.id ?? "", "copy.other.1")
        XCTAssertEqual(center.current?.message ?? "", "复制功能筹备中")
        center.cancel()
    }

    func testTenOpenCardCallsKeepOneToastAndDoNotMutateMessage() {
        let (center, handler) = makeHandler()
        let message = YZMockData.threeMessages[0]
        let snapshot = message

        for _ in 0..<10 {
            handler.openCard(message)
        }

        XCTAssertEqual(center.current?.id ?? "", "card.other.1")
        XCTAssertEqual(message, snapshot)
        center.cancel()
    }
}

@MainActor
final class DialogViewModelTests: XCTestCase {
    func testRevealIsRecordedOnce() {
        let viewModel = DialogViewModel()
        viewModel.reveal("other.1")
        viewModel.reveal("other.1")
        XCTAssertEqual(viewModel.revealedMessageIDs, ["other.1"])
    }

    func testResetClearsRevealedMessages() {
        let viewModel = DialogViewModel()
        viewModel.reveal("mine.1")
        viewModel.resetReveals()
        XCTAssertTrue(viewModel.revealedMessageIDs.isEmpty)
    }

    func testOpenComposerStartsPresentedAndBlank() {
        let viewModel = DialogViewModel()
        viewModel.openComposer()
        XCTAssertTrue(viewModel.isComposerPresented)
        XCTAssertTrue(viewModel.draft.isEmpty)
        XCTAssertFalse(viewModel.canSend)
    }

    func testCloseComposerDiscardsDraft() {
        let viewModel = DialogViewModel()
        viewModel.openComposer()
        viewModel.draft = "临时草稿"
        viewModel.closeComposer()
        XCTAssertFalse(viewModel.isComposerPresented)
        XCTAssertTrue(viewModel.draft.isEmpty)
        viewModel.openComposer()
        XCTAssertTrue(viewModel.draft.isEmpty)
    }

    func testSubmitBlankDoesNothing() {
        let state = YZAppState(session: YZMockData.session(baseline: .threeMessages))
        let viewModel = DialogViewModel()
        viewModel.openComposer()
        viewModel.draft = "   "
        let before = state.messages.count
        XCTAssertNil(viewModel.submit(state: state))
        XCTAssertEqual(state.messages.count, before)
        XCTAssertTrue(viewModel.isComposerPresented)
    }

    func testSubmitAddsOneMessageClearsDraftAndKeepsDrawer() {
        let state = YZAppState(session: YZMockData.session(baseline: .threeMessages))
        let viewModel = DialogViewModel()
        viewModel.openComposer()
        viewModel.draft = "请把关键信息写下来。"
        let before = state.messages.count

        let id = viewModel.submit(state: state)

        XCTAssertEqual(id ?? "", "mine.c1")
        XCTAssertEqual(state.messages.count, before + 1)
        XCTAssertTrue(viewModel.draft.isEmpty)
        XCTAssertTrue(viewModel.isComposerPresented)
        XCTAssertEqual(viewModel.pendingScrollMessageID ?? "", "mine.c1")
    }

    func testTenSubmitsProduceOnlyOneMessage() {
        let state = YZAppState(session: YZMockData.session(baseline: .threeMessages))
        let viewModel = DialogViewModel()
        viewModel.openComposer()
        viewModel.draft = "只发送一次。"
        let before = state.messages.count

        for _ in 0..<10 {
            _ = viewModel.submit(state: state)
        }

        XCTAssertEqual(state.messages.count, before + 1)
    }

    func testConsumePendingScrollClearsAnchor() {
        let state = YZAppState(session: YZMockData.session(baseline: .threeMessages))
        let viewModel = DialogViewModel()
        viewModel.openComposer()
        viewModel.draft = "滚动一次。"
        _ = viewModel.submit(state: state)
        XCTAssertNotNil(viewModel.pendingScrollMessageID)
        viewModel.consumePendingScroll()
        XCTAssertNil(viewModel.pendingScrollMessageID)
    }
}