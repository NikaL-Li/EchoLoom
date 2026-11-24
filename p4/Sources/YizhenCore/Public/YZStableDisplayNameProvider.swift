import Foundation

/// 默认显示名提供者：始终返回 nil，导出时回退到稳定标识。
public struct YZStableDisplayNameProvider: YZSessionDisplayNameProviding {
    public init() {}

    public func displayName(forScenario id: String) -> String? {
        nil
    }

    public func displayName(forPhase id: String) -> String? {
        nil
    }
}