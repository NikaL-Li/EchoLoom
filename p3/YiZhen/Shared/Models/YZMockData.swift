import Foundation

enum YZMockData {
    static let emergencyBannerText = "我听不见，请帮我打 120"
    static let emergencyCardText = "我听不见，请帮我打 120。"

    static let scenes: [YZScene] = scenePacks.map(\.scene)

    static let scenePacks: [YZScenePack] = [
        YZScenePack(
            scene: YZScene(id: "medical", name: "就医", order: 0, isSelected: true, isEmergency: false),
            navStyle: .step,
            phases: makePhases(
                "medical",
                [("register", "挂号"), ("question", "问诊"), ("exam", "检查"), ("pharmacy", "取药"), ("payment", "缴费")],
                current: "medical.question"
            )
        ),
        YZScenePack(
            scene: YZScene(id: "meal", name: "点餐", order: 1, isSelected: false, isEmergency: false),
            navStyle: .tab,
            phases: makePhases("meal", [("order", "点单"), ("taste", "口味"), ("pack", "打包"), ("checkout", "结账")])
        ),
        YZScenePack(
            scene: YZScene(id: "travel", name: "出行", order: 2, isSelected: false, isEmergency: false),
            navStyle: .tab,
            phases: makePhases("travel", [("taxi", "打车"), ("transit", "公交地铁"), ("ask", "问路"), ("alight", "下车")])
        ),
        YZScenePack(
            scene: YZScene(id: "service", name: "办事", order: 3, isSelected: false, isEmergency: false),
            navStyle: .tab,
            phases: makePhases("service", [("bank", "银行"), ("government", "政务"), ("express", "快递"), ("campus", "校园")])
        ),
        YZScenePack(
            scene: YZScene(id: "emergency", name: "紧急", order: 4, isSelected: false, isEmergency: true),
            navStyle: .tab,
            phases: makePhases("emergency", [("help", "求助"), ("police", "报警"), ("sick", "身体不适")])
        )
    ]

    static let phases: [YZPhase] = phases(for: "medical")

    static let threeMessages: [YZMessage] = [
        YZMessage(
            id: "other.1",
            direction: .other,
            text: "请问您哪里不舒服？",
            statusText: "已识别",
            createdAt: date(hour: 9, minute: 41)
        ),
        YZMessage(
            id: "mine.1",
            direction: .mine,
            text: "我听力不好，请说慢一点。",
            statusText: "文字直达",
            createdAt: date(hour: 9, minute: 41)
        ),
        YZMessage(
            id: "mine.2",
            direction: .mine,
            text: "我需要做一次血常规检查。",
            statusText: "文字直达",
            createdAt: date(hour: 9, minute: 42)
        )
    ]

    static func phases(for sceneID: YZScene.ID) -> [YZPhase] {
        scenePacks.first(where: { $0.scene.id == sceneID })?.phases.sorted { $0.order < $1.order } ?? []
    }

    static func navStyle(of sceneID: YZScene.ID) -> YZNavStyle {
        scenePacks.first(where: { $0.scene.id == sceneID })?.navStyle ?? .step
    }

    static func defaultPhaseID(for sceneID: YZScene.ID) -> YZPhase.ID? {
        if sceneID == "medical" {
            return "medical.question"
        }
        return phases(for: sceneID).first?.id
    }

    static func phrases(sceneID: YZScene.ID, phaseID: YZPhase.ID) -> [YZPhrase] {
        let texts = phraseTexts[sceneID]?[phaseID] ?? []
        return texts.enumerated().map { index, text in
            YZPhrase(id: "\(phaseID).\(index + 1)", text: text, placeholder: true)
        }
    }

    static func session(
        baseline: YZBaseline = .threeMessages,
        phraseBaseline: YZPhraseBaseline = .six
    ) -> YZDialogSession {
        let defaultPhrases = phraseBaseline == .empty ? [] : phrases(sceneID: "medical", phaseID: "medical.question")
        return YZDialogSession(
            scenes: scenes,
            phases: phases(for: "medical"),
            messages: baseline == .empty ? [] : threeMessages,
            phrases: defaultPhrases
        )
    }

    private static func makePhases(
        _ sceneID: String,
        _ items: [(String, String)],
        current: String? = nil
    ) -> [YZPhase] {
        items.enumerated().map { index, item in
            let id = "\(sceneID).\(item.0)"
            return YZPhase(id: id, name: item.1, order: index, isCurrent: id == current)
        }
    }

    private static func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    private static let phraseTexts: [String: [String: [String]]] = [
        "medical": [
            "medical.register": [
                "你好，我想挂号。",
                "请问内科在几楼？",
                "我没有预约，能现场挂号吗？",
                "我想挂专家号。",
                "请问要带身份证吗？",
                "挂完号去哪里等？"
            ],
            "medical.question": [
                "我头晕、头痛。",
                "已经疼了三天。",
                "我没有药物过敏。",
                "这个药我吃过，一天两次。",
                "请说慢一点，我看你的字。",
                "请写下来给我看。"
            ],
            "medical.exam": [
                "需要做什么检查？",
                "抽血要空腹吗？",
                "报告什么时候能出？",
                "在哪里取报告？",
                "拍片在几楼？",
                "结果能发到我手机上吗？"
            ],
            "medical.pharmacy": [
                "药一天吃几次？",
                "饭前还是饭后？",
                "这个药和我别的药会冲突吗？",
                "一次吃几片？",
                "吃完要复查吗？",
                "有副作用要停药吗？"
            ],
            "medical.payment": [
                "在哪里缴费？",
                "可以手机支付吗？",
                "能开发票吗？",
                "医保能报销吗？",
                "缴完费下一步去哪？",
                "一共多少钱？"
            ]
        ],
        "meal": [
            "meal.order": [
                "你好，我要点单。",
                "这个菜辣吗？",
                "有素食吗？",
                "请给我一份米饭。",
                "不要放香菜。",
                "多久能做好？"
            ],
            "meal.taste": [
                "少放盐，谢谢。",
                "不要太辣。",
                "请少放糖。",
                "酱料分开装。",
                "我对花生过敏。",
                "可以换成清汤吗？"
            ],
            "meal.pack": [
                "请帮我打包。",
                "分开装，谢谢。",
                "需要打包盒。",
                "汤不要洒出来。",
                "可以多给一双筷子吗？",
                "结账在哪里？"
            ],
            "meal.checkout": [
                "一共多少钱？",
                "可以手机支付吗？",
                "能开发票吗？",
                "请给我小票。",
                "我用了优惠券。",
                "谢谢，不用找了。"
            ]
        ],
        "travel": [
            "travel.taxi": [
                "请带我去火车站。",
                "大概要多久？",
                "走高速可以吗？",
                "在这里停车。",
                "车费多少钱？",
                "可以扫码吗？"
            ],
            "travel.transit": [
                "这辆车到人民广场吗？",
                "我要坐几站？",
                "到哪里换乘？",
                "末班车几点？",
                "请提醒我下车。",
                "地铁站怎么走？"
            ],
            "travel.ask": [
                "请问洗手间在哪？",
                "去机场怎么走？",
                "这附近有药店吗？",
                "我迷路了。",
                "请帮我看看地图。",
                "可以带我一段吗？"
            ],
            "travel.alight": [
                "下一站下车。",
                "请开一下门。",
                "我坐过站了。",
                "这里可以下车吗？",
                "出口在哪边？",
                "谢谢，我到了。"
            ]
        ],
        "service": [
            "service.bank": [
                "我要取钱。",
                "我要开一张卡。",
                "这个业务在哪个窗口？",
                "需要带什么材料？",
                "可以代办吗？",
                "大概要等多久？"
            ],
            "service.government": [
                "我要办身份证。",
                "这个窗口对吗？",
                "需要复印材料吗？",
                "表格怎么填？",
                "可以网上预约吗？",
                "多久能办好？"
            ],
            "service.express": [
                "我要寄快递。",
                "这个能寄吗？",
                "运费多少钱？",
                "多久能到？",
                "请帮我打包。",
                "我要取快递。"
            ],
            "service.campus": [
                "教学楼怎么走？",
                "图书馆在哪？",
                "我要找辅导员。",
                "这个教室怎么走？",
                "食堂几点开门？",
                "可以帮我签到吗？"
            ]
        ],
        "emergency": [
            "emergency.help": [
                "请帮我一下。",
                "我听不见，请写字给我。",
                "请叫工作人员。",
                "我需要翻译。",
                "请打 120。",
                "谢谢你的帮助。"
            ],
            "emergency.police": [
                "我要报警。",
                "我的包丢了。",
                "有人跟着我。",
                "请帮我联系警察。",
                "我在这里等。",
                "请记录我的位置。"
            ],
            "emergency.sick": [
                "我很不舒服。",
                "我头晕，站不稳。",
                "请帮我坐下。",
                "我有心脏病。",
                "请叫救护车。",
                "我的药在这里。"
            ]
        ]
    ]
}