import XCTest
import SwiftUI
@testable import YiZhen

final class PhaseStepStateTests: XCTestCase {
    func testStateSequenceWhenSecondItemIsCurrent() {
        XCTAssertEqual(PhaseStepStateResolver.state(index: 0, currentIndex: 1), .done)
        XCTAssertEqual(PhaseStepStateResolver.state(index: 1, currentIndex: 1), .current)
        XCTAssertEqual(PhaseStepStateResolver.state(index: 2, currentIndex: 1), .upcoming)
    }

    func testFirstAndLastCurrent() {
        XCTAssertEqual(PhaseStepStateResolver.state(index: 0, currentIndex: 0), .current)
        XCTAssertEqual(PhaseStepStateResolver.state(index: 1, currentIndex: 0), .upcoming)
        XCTAssertEqual(PhaseStepStateResolver.state(index: 0, currentIndex: 4), .done)
        XCTAssertEqual(PhaseStepStateResolver.state(index: 4, currentIndex: 4), .current)
    }

    func testNilCurrentMakesEverythingUpcoming() {
        for index in 0..<5 {
            XCTAssertEqual(PhaseStepStateResolver.state(index: index, currentIndex: nil), .upcoming)
        }
    }

    func testAccessibilityValues() {
        XCTAssertEqual(PhaseStepState.done.accessibilityValue, "已完成")
        XCTAssertEqual(PhaseStepState.current.accessibilityValue, "当前")
        XCTAssertEqual(PhaseStepState.upcoming.accessibilityValue, "未开始")
    }

    func testLineColors() {
        let colors = YZColorTokens.light
        XCTAssertNil(PhaseStepStateResolver.lineColor(index: 0, currentIndex: 2, colors: colors))
        XCTAssertNotNil(PhaseStepStateResolver.lineColor(index: 1, currentIndex: 2, colors: colors))
        XCTAssertNotNil(PhaseStepStateResolver.lineColor(index: 2, currentIndex: 2, colors: colors))
        XCTAssertNotNil(PhaseStepStateResolver.lineColor(index: 3, currentIndex: 2, colors: colors))
    }
}