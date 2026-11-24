#if DEBUG
import Foundation

enum YZSampleData {
    static let sessions: [YZSession] = {
        let now = Date()
        return [
            YZSession(
                scene: .medical,
                subScene: "问诊",
                startedAt: now.addingTimeInterval(-600),
                endedAt: now.addingTimeInterval(-420),
                turns: [
                    YZTurn(role: .other, text: "哪里不舒服？", status: "文字直达", date: now.addingTimeInterval(-560)),
                    YZTurn(role: .me, text: "我最近总是头晕。", status: "已播报", date: now.addingTimeInterval(-520)),
                    YZTurn(role: .other, text: "持续多久了？", status: "文字直达", date: now.addingTimeInterval(-480))
                ]
            )
        ]
    }()

    static let phrases: [String: [String]] = [
        YZAppState.phraseKey(scene: .medical, subScene: "问诊"): [
            "我头晕、头痛。",
            "已经疼了三天。",
            "我没有药物过敏。",
            "这个药我吃过，一天两次。",
            "请说慢一点，我看你的字。",
            "请写下来给我看。"
        ]
    ]
}
#endif