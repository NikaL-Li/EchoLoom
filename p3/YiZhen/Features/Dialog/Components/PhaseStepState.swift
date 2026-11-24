import SwiftUI

enum PhaseStepState: String, Equatable, Hashable {
    case done
    case current
    case upcoming

    var accessibilityValue: String {
        switch self {
        case .done: return "已完成"
        case .current: return "当前"
        case .upcoming: return "未开始"
        }
    }
}

enum PhaseStepStateResolver {
    static func state(index: Int, currentIndex: Int?) -> PhaseStepState {
        guard let currentIndex else { return .upcoming }
        if index < currentIndex { return .done }
        if index == currentIndex { return .current }
        return .upcoming
    }

    static func lineColor(index: Int, currentIndex: Int?, colors: YZColorTokens) -> Color? {
        guard index > 0 else { return nil }
        return state(index: index, currentIndex: currentIndex) == .done ? colors.stepDoneLine : colors.stepIdle
    }
}