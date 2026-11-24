#if DEBUG
import Foundation

final class YZPreviewPhraseStore: YZCustomPhraseStoring {
    private var map: [String: [String]] = [
        YZUserDefaultsPhraseStore.groupKey(scene: .medical, sub: "问诊"): ["我对青霉素过敏。"]
    ]

    func customPhrases(scene: SceneKind, sub: String) throws -> [String] {
        map[YZUserDefaultsPhraseStore.groupKey(scene: scene, sub: sub)] ?? []
    }

    func allCustomPhrases() throws -> [String: [String]] {
        map
    }

    func addPhrase(_ text: String, scene: SceneKind, sub: String) throws {
        let key = YZUserDefaultsPhraseStore.groupKey(scene: scene, sub: sub)
        map[key, default: []].append(text)
    }

    func updatePhrase(_ original: String, to text: String, scene: SceneKind, sub: String) throws {}

    func deletePhrase(_ text: String, scene: SceneKind, sub: String) throws {}
}

enum YZPreviewData {
    static let sessions: [YZSession] = {
        let now = Date()
        return [
            YZSession(
                scene: .medical,
                subScene: "问诊",
                startedAt: now.addingTimeInterval(-1500),
                endedAt: now.addingTimeInterval(-900),
                turns: [
                    YZTurn(role: .other, text: "哪里不舒服？", status: "已识别", date: now.addingTimeInterval(-1400)),
                    YZTurn(role: .me, text: "我最近总是头晕，已经三天了。", status: "已播报", date: now.addingTimeInterval(-1350)),
                    YZTurn(role: .other, text: "先量一下血压，再去做血常规检查。", status: "已识别", date: now.addingTimeInterval(-1250)),
                    YZTurn(role: .me, text: "检查在哪里做？", status: "已播报", date: now.addingTimeInterval(-1180)),
                    YZTurn(role: .other, text: "二楼检验科，先去一楼缴费。", status: "已识别", date: now.addingTimeInterval(-1100)),
                    YZTurn(role: .me, text: "好的，谢谢医生。", status: "已播报", date: now.addingTimeInterval(-1000))
                ]
            ),
            YZSession(
                scene: .dining,
                subScene: "点单",
                startedAt: now.addingTimeInterval(-86400 * 2),
                endedAt: now.addingTimeInterval(-86400 * 2 + 240),
                turns: [
                    YZTurn(role: .me, text: "请给我看菜单。", status: "已播报", date: now.addingTimeInterval(-86400 * 2 + 60)),
                    YZTurn(role: .other, text: "扫码就可以点单。", status: "已识别", date: now.addingTimeInterval(-86400 * 2 + 120)),
                    YZTurn(role: .me, text: "不要香菜，少辣。", status: "已播报", date: now.addingTimeInterval(-86400 * 2 + 180))
                ]
            )
        ]
    }()
}

@MainActor
extension YZAppState {
    static var preview: YZAppState {
        let state = YZAppState(
            sessionStore: YZMemorySessionStore(sessions: YZPreviewData.sessions),
            customPhraseStore: YZPreviewPhraseStore()
        )
        state.totalSavedCount = 12
        return state
    }
}
#endif
