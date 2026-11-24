import Foundation

/// 显示名解析的最小契约。取不到显示名时返回 nil，由导出层回退稳定标识。
public protocol YZSessionDisplayNameProviding: Sendable {
    func displayName(forScenario id: String) -> String?
    func displayName(forPhase id: String) -> String?
}