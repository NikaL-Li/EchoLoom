import Foundation

public enum SceneKind: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case medical = "就医"
    case dining = "点餐"
    case transit = "出行"
    case errands = "办事"
    case emergency = "紧急"

    public var id: String { rawValue }
    public var title: String { rawValue }
}

public enum SceneNavStyle: String, Codable, Hashable, Sendable {
    case step
    case tab
}

public struct Term: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let category: String
    public let standard: String
    public let colloquial: String
    public let ask: String

    public init(id: String, category: String, standard: String, colloquial: String, ask: String) {
        self.id = id
        self.category = category
        self.standard = standard
        self.colloquial = colloquial
        self.ask = ask
    }
}

public struct ScenePack: Identifiable, Sendable {
    public let scene: SceneKind
    public let navStyle: SceneNavStyle
    public let subs: [String]
    public let phrases: [String: [String]]
    public let terms: [Term]

    public var id: String { scene.id }

    public var defaultSub: String {
        scene == .medical ? "问诊" : (subs.first ?? "")
    }

    public init(
        scene: SceneKind,
        navStyle: SceneNavStyle,
        subs: [String],
        phrases: [String: [String]],
        terms: [Term]
    ) {
        self.scene = scene
        self.navStyle = navStyle
        self.subs = subs
        self.phrases = phrases
        self.terms = terms
    }

    public func phrases(for sub: String) -> [String] {
        let key = subs.contains(sub) ? sub : (subs.first ?? "")
        return phrases[key] ?? []
    }
}

public enum SceneCatalog {
    public static let scenes: [SceneKind] = SceneKind.allCases

    public static let all: [ScenePack] = [
        medicalPack,
        diningPack,
        transitPack,
        errandsPack,
        emergencyPack
    ]

    private static let index: [SceneKind: ScenePack] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.scene, $0) }
    )

    public static func pack(for scene: SceneKind) -> ScenePack {
        if let pack = index[scene] { return pack }
        return ScenePack(scene: scene, navStyle: .tab, subs: [], phrases: [:], terms: [])
    }

    public static func subs(for scene: SceneKind) -> [String] {
        pack(for: scene).subs
    }

    public static func defaultSub(for scene: SceneKind) -> String {
        pack(for: scene).defaultSub
    }

    public static func phrases(for scene: SceneKind, sub: String) -> [String] {
        pack(for: scene).phrases(for: sub)
    }

    public static func terms(for scene: SceneKind) -> [Term] {
        pack(for: scene).terms
    }

    public static var allTerms: [Term] {
        all.flatMap(\.terms)
    }

    private static let medicalPack = ScenePack(
        scene: .medical,
        navStyle: .step,
        subs: ["挂号", "问诊", "检查", "取药", "缴费"],
        phrases: [
            "挂号": ["你好，我想挂号。", "请问内科在几楼？", "我没有预约，能现场挂吗？", "我想挂专家号。", "请问要带身份证吗？", "挂完号去哪里等？"],
            "问诊": ["我头晕、头痛。", "已经疼了三天。", "我没有药物过敏。", "这个药我吃过，一天两次。", "请说慢一点，我看你的字。", "请写下来给我看。"],
            "检查": ["需要做什么检查？", "抽血要空腹吗？", "报告什么时候能出？", "在哪里取报告？", "拍片在几楼？", "结果能发到我手机上吗？"],
            "取药": ["药一天吃几次？", "饭前还是饭后？", "这个药和我别的药会冲突吗？", "一次吃几片？", "吃完要复查吗？", "有副作用要停药吗？"],
            "缴费": ["在哪里缴费？", "可以手机支付吗？", "能开发票吗？", "医保能报销吗？", "缴完费下一步去哪？", "一共多少钱？"]
        ],
        terms: [
            Term(id: "t01", category: "症状", standard: "持续性疼痛", colloquial: "一直疼", ask: "疼了几天了？"),
            Term(id: "t02", category: "症状", standard: "阵发性疼痛", colloquial: "一阵一阵疼", ask: "多久疼一次？"),
            Term(id: "t03", category: "症状", standard: "放射性疼痛", colloquial: "疼得串到别处", ask: "疼的时候会往哪里窜？"),
            Term(id: "t04", category: "症状", standard: "头晕", colloquial: "头昏昏的", ask: "是天旋地转还是昏沉？"),
            Term(id: "t05", category: "症状", standard: "眩晕", colloquial: "一站起来就转", ask: "改变体位会加重吗？"),
            Term(id: "t06", category: "症状", standard: "头痛", colloquial: "脑袋疼", ask: "哪个位置疼？"),
            Term(id: "t07", category: "症状", standard: "发热", colloquial: "发烧", ask: "最高烧到多少度？"),
            Term(id: "t08", category: "症状", standard: "畏寒", colloquial: "怕冷", ask: "有没有打寒战？"),
            Term(id: "t09", category: "症状", standard: "乏力", colloquial: "没力气", ask: "这种情况多久了？"),
            Term(id: "t10", category: "症状", standard: "恶心", colloquial: "想吐", ask: "吐过没有？"),
            Term(id: "t11", category: "症状", standard: "呕吐", colloquial: "吐了", ask: "吐了几次？什么颜色？"),
            Term(id: "t12", category: "症状", standard: "腹泻", colloquial: "拉肚子", ask: "一天拉几次？水样吗？"),
            Term(id: "t13", category: "症状", standard: "便秘", colloquial: "拉不出来", ask: "几天一次？"),
            Term(id: "t14", category: "症状", standard: "咳嗽", colloquial: "咳", ask: "干咳还是有痰？"),
            Term(id: "t15", category: "症状", standard: "咳痰", colloquial: "有痰", ask: "痰是什么颜色？"),
            Term(id: "t16", category: "症状", standard: "气短", colloquial: "喘不上气", ask: "活动后加重吗？"),
            Term(id: "t17", category: "症状", standard: "心悸", colloquial: "心慌", ask: "发作时脉搏快吗？"),
            Term(id: "t18", category: "症状", standard: "胸闷", colloquial: "胸口堵", ask: "和活动有关系吗？"),
            Term(id: "t19", category: "症状", standard: "水肿", colloquial: "肿了", ask: "早上肿还是晚上肿？"),
            Term(id: "t20", category: "症状", standard: "失眠", colloquial: "睡不着", ask: "入睡困难还是容易醒？"),
            Term(id: "t21", category: "症状", standard: "食欲减退", colloquial: "不想吃饭", ask: "体重有没有下降？"),
            Term(id: "t22", category: "症状", standard: "麻木", colloquial: "发麻", ask: "哪几个手指麻？"),
            Term(id: "t23", category: "症状", standard: "瘙痒", colloquial: "痒", ask: "有没有起疹子？"),
            Term(id: "t24", category: "症状", standard: "视物模糊", colloquial: "看东西模糊", ask: "是一只眼还是两只？"),
            Term(id: "t25", category: "部位", standard: "头部", colloquial: "脑袋", ask: "具体哪里不舒服？"),
            Term(id: "t26", category: "部位", standard: "颈部", colloquial: "脖子", ask: "转动脖子会疼吗？"),
            Term(id: "t27", category: "部位", standard: "肩部", colloquial: "肩膀", ask: "抬胳膊受影响吗？"),
            Term(id: "t28", category: "部位", standard: "胸部", colloquial: "胸口", ask: "深呼吸会疼吗？"),
            Term(id: "t29", category: "部位", standard: "腹部", colloquial: "肚子", ask: "是上腹还是下腹？"),
            Term(id: "t30", category: "部位", standard: "腰背部", colloquial: "后腰", ask: "弯腰时加重吗？"),
            Term(id: "t31", category: "部位", standard: "上肢", colloquial: "胳膊", ask: "哪一侧？"),
            Term(id: "t32", category: "部位", standard: "下肢", colloquial: "腿", ask: "走路受影响吗？"),
            Term(id: "t33", category: "部位", standard: "膝关节", colloquial: "膝盖", ask: "上下楼疼吗？"),
            Term(id: "t34", category: "部位", standard: "咽喉", colloquial: "嗓子", ask: "吞咽疼吗？"),
            Term(id: "t35", category: "部位", standard: "口腔", colloquial: "嘴", ask: "溃疡还是牙痛？"),
            Term(id: "t36", category: "部位", standard: "皮肤", colloquial: "身上起东西", ask: "哪个部位？范围多大？"),
            Term(id: "t37", category: "检查", standard: "血常规", colloquial: "抽血", ask: "最近一次是什么时候？"),
            Term(id: "t38", category: "检查", standard: "尿常规", colloquial: "验尿", ask: "留晨尿了吗？"),
            Term(id: "t39", category: "检查", standard: "肝功能", colloquial: "查肝", ask: "空腹抽的血吗？"),
            Term(id: "t40", category: "检查", standard: "肾功能", colloquial: "查肾", ask: "有没有复查过？"),
            Term(id: "t41", category: "检查", standard: "血糖", colloquial: "查血糖", ask: "空腹还是餐后？"),
            Term(id: "t42", category: "检查", standard: "心电图", colloquial: "做心电图", ask: "有报告单吗？"),
            Term(id: "t43", category: "检查", standard: "胸部X线", colloquial: "拍胸片", ask: "最近拍过吗？"),
            Term(id: "t44", category: "检查", standard: "CT检查", colloquial: "做CT", ask: "带片子来了吗？"),
            Term(id: "t45", category: "检查", standard: "磁共振", colloquial: "做核磁", ask: "体内有金属植入物吗？"),
            Term(id: "t46", category: "检查", standard: "B超", colloquial: "做B超", ask: "需要憋尿，能做到吗？"),
            Term(id: "t47", category: "检查", standard: "胃镜", colloquial: "做胃镜", ask: "之前做过吗？"),
            Term(id: "t48", category: "检查", standard: "病理检查", colloquial: "活检", ask: "取样结果出来了吗？"),
            Term(id: "t49", category: "用药", standard: "口服", colloquial: "吃药", ask: "一天几次？"),
            Term(id: "t50", category: "用药", standard: "静脉输液", colloquial: "打点滴", ask: "今天输第几天？"),
            Term(id: "t51", category: "用药", standard: "肌肉注射", colloquial: "打针", ask: "打在哪个部位？"),
            Term(id: "t52", category: "用药", standard: "外用", colloquial: "抹药", ask: "一天抹几次？"),
            Term(id: "t53", category: "用药", standard: "舌下含服", colloquial: "含在舌头下", ask: "含多久？"),
            Term(id: "t54", category: "用药", standard: "餐前服用", colloquial: "饭前吃", ask: "提前多久？"),
            Term(id: "t55", category: "用药", standard: "餐后服用", colloquial: "饭后吃", ask: "饭后多久？"),
            Term(id: "t56", category: "用药", standard: "每日一次", colloquial: "一天一次", ask: "固定时间吗？"),
            Term(id: "t57", category: "用药", standard: "抗生素", colloquial: "消炎药", ask: "吃了几天？"),
            Term(id: "t58", category: "用药", standard: "止痛药", colloquial: "止疼片", ask: "一天吃了几次？"),
            Term(id: "t59", category: "用药", standard: "降压药", colloquial: "降压的", ask: "平时血压多少？"),
            Term(id: "t60", category: "用药", standard: "药物过敏", colloquial: "过敏", ask: "对什么药过敏？"),
            Term(id: "t61", category: "流程", standard: "挂号", colloquial: "挂个号", ask: "挂哪个科？"),
            Term(id: "t62", category: "流程", standard: "分诊", colloquial: "分诊台", ask: "先去分诊台测体温？"),
            Term(id: "t63", category: "流程", standard: "缴费", colloquial: "交钱", ask: "自助机还是窗口？"),
            Term(id: "t64", category: "流程", standard: "取药", colloquial: "拿药", ask: "药房在几楼？"),
            Term(id: "t65", category: "流程", standard: "检查预约", colloquial: "约检查", ask: "约到几号？"),
            Term(id: "t66", category: "流程", standard: "住院", colloquial: "住进来", ask: "床位安排了吗？"),
            Term(id: "t67", category: "流程", standard: "手术", colloquial: "做手术", ask: "术前禁食了吗？"),
            Term(id: "t68", category: "流程", standard: "复诊", colloquial: "再来一次", ask: "什么时候来复查？"),
            Term(id: "t69", category: "流程", standard: "转诊", colloquial: "转到别的科", ask: "需要开转诊单吗？"),
            Term(id: "t70", category: "流程", standard: "医保", colloquial: "报销", ask: "带医保卡了吗？")
        ]
    )

    private static let diningPack = ScenePack(
        scene: .dining,
        navStyle: .tab,
        subs: ["点单", "口味", "打包", "结账"],
        phrases: [
            "点单": ["我要这个。", "请给我看菜单。", "这个辣不辣？", "有推荐的吗？", "能不能少放一点？", "我要一份，谢谢。"],
            "口味": ["不要香菜。", "少冰、半糖。", "不要葱、不要蒜。", "微辣就可以。", "不要放味精。", "米饭少一点。"],
            "打包": ["打包带走，谢谢。", "帮我分开装。", "请给我一双筷子。", "有袋子吗？", "汤麻烦封好，别洒。", "一共多少钱？"],
            "结账": ["买单，谢谢。", "可以扫码吗？", "能开发票吗？", "我付现金。", "请给我小票。", "不用找了。"]
        ],
        terms: [
            Term(id: "c01", category: "点餐", standard: "点单", colloquial: "点菜", ask: "现在可以点吗？"),
            Term(id: "c02", category: "点餐", standard: "菜单", colloquial: "菜谱", ask: "需要看菜单吗？"),
            Term(id: "c03", category: "点餐", standard: "忌口", colloquial: "不能吃", ask: "有什么不吃的？"),
            Term(id: "c04", category: "点餐", standard: "食物过敏", colloquial: "吃了过敏", ask: "对什么食物过敏？"),
            Term(id: "c05", category: "点餐", standard: "辣度", colloquial: "辣不辣", ask: "要微辣还是不辣？"),
            Term(id: "c06", category: "点餐", standard: "打包", colloquial: "带走", ask: "需要打包吗？"),
            Term(id: "c07", category: "点餐", standard: "结账", colloquial: "买单", ask: "现在结账吗？"),
            Term(id: "c08", category: "点餐", standard: "分开付款", colloquial: "各付各的", ask: "要分开付吗？"),
            Term(id: "c09", category: "点餐", standard: "等位", colloquial: "排队", ask: "几位？现在需要等位。"),
            Term(id: "c10", category: "点餐", standard: "加菜", colloquial: "再加一个", ask: "还要加什么？")
        ]
    )

    private static let transitPack = ScenePack(
        scene: .transit,
        navStyle: .tab,
        subs: ["打车", "公交地铁", "问路", "下车"],
        phrases: [
            "打车": ["我在南门便利店门口。", "车牌尾号是 3721。", "到前面路口停就行。", "我听不见，请发文字给我。", "麻烦等我两分钟。", "我到了，你在哪？"],
            "公交地铁": ["下一站是哪里？", "到火车站还有几站？", "这趟车到大学城吗？", "到站请提醒我。", "末班车几点？", "在哪里换乘？"],
            "问路": ["请问洗手间在哪？", "请问 3 号楼怎么走？", "这里能出去吗？", "麻烦指一下方向。", "有电梯吗？", "谢谢。"],
            "下车": ["我在这站下。", "师傅，前面停一下。", "到了请提醒我。", "我坐过站了，怎么办？", "麻烦开一下门。", "谢谢师傅。"]
        ],
        terms: [
            Term(id: "r01", category: "出行", standard: "目的地", colloquial: "要去的地方", ask: "您要去哪里？"),
            Term(id: "r02", category: "出行", standard: "地铁站", colloquial: "地铁", ask: "最近的地铁站是哪个？"),
            Term(id: "r03", category: "出行", standard: "公交站", colloquial: "公交", ask: "要坐哪路公交？"),
            Term(id: "r04", category: "出行", standard: "换乘", colloquial: "倒车", ask: "需要换乘吗？"),
            Term(id: "r05", category: "出行", standard: "坐过站", colloquial: "过站了", ask: "在哪一站坐过的？"),
            Term(id: "r06", category: "出行", standard: "到站提醒", colloquial: "提醒我下车", ask: "到哪一站提醒您？"),
            Term(id: "r07", category: "出行", standard: "出租车", colloquial: "打车", ask: "需要帮您叫车吗？"),
            Term(id: "r08", category: "出行", standard: "购票", colloquial: "买票", ask: "买到哪一站？"),
            Term(id: "r09", category: "出行", standard: "末班车", colloquial: "最后一班", ask: "要赶末班车吗？"),
            Term(id: "r10", category: "出行", standard: "无障碍通道", colloquial: "无障碍电梯", ask: "需要走无障碍通道吗？")
        ]
    )

    private static let errandsPack = ScenePack(
        scene: .errands,
        navStyle: .tab,
        subs: ["银行", "政务", "快递", "校园"],
        phrases: [
            "银行": ["我要开一张卡。", "需要带什么材料？", "这个业务在哪个窗口？", "能帮我取个号吗？", "我要转账。", "请把流程写给我看。"],
            "政务": ["我要办居住证。", "需要哪些材料？", "在哪个窗口办？", "可以网上办吗？", "多久能办好？", "能帮我复印一份吗？"],
            "快递": ["我有三个件要寄。", "放门口就行。", "放驿站，不要按门铃。", "到付还是现付？", "能保价吗？", "单号发我手机上。"],
            "校园": ["请问教务处怎么走？", "我要办在读证明。", "盖章在哪个办公室？", "几点下班？", "需要预约吗？", "能帮我打电话问一下吗？"]
        ],
        terms: [
            Term(id: "g01", category: "办事", standard: "取号", colloquial: "拿号", ask: "取号了吗？"),
            Term(id: "g02", category: "办事", standard: "窗口", colloquial: "柜台", ask: "去哪个窗口？"),
            Term(id: "g03", category: "办事", standard: "表格", colloquial: "单子", ask: "表格填好了吗？"),
            Term(id: "g04", category: "办事", standard: "材料", colloquial: "资料", ask: "材料带齐了吗？"),
            Term(id: "g05", category: "办事", standard: "复印件", colloquial: "复印", ask: "需要复印件吗？"),
            Term(id: "g06", category: "办事", standard: "回执", colloquial: "凭证", ask: "需要回执吗？"),
            Term(id: "g07", category: "办事", standard: "预约", colloquial: "约号", ask: "预约了吗？"),
            Term(id: "g08", category: "办事", standard: "补材料", colloquial: "补交", ask: "还需要补什么？"),
            Term(id: "g09", category: "办事", standard: "身份证", colloquial: "证件", ask: "带身份证了吗？"),
            Term(id: "g10", category: "办事", standard: "办理进度", colloquial: "办到哪了", ask: "要查询进度吗？")
        ]
    )

    private static let emergencyPack = ScenePack(
        scene: .emergency,
        navStyle: .tab,
        subs: ["求助", "报警", "身体不适"],
        phrases: [
            "求助": ["我听不见，请帮我一下。", "请帮我打 120。", "我找不到家人了。", "请帮我叫工作人员。", "我不会说，请看屏幕。", "谢谢您。"],
            "报警": ["我要报警。", "我听不见，请用文字和我沟通。", "我的位置是……", "有人一直跟着我。", "我的东西被偷了。", "请派人过来。"],
            "身体不适": ["我胸口疼。", "我头晕，站不稳。", "我需要看急诊。", "我对青霉素过敏。", "我在吃这些药。", "请帮我联系家属。"]
        ],
        terms: [
            Term(id: "e01", category: "紧急", standard: "急救", colloquial: "叫救护车", ask: "需要我帮你拨 120 吗？"),
            Term(id: "e02", category: "紧急", standard: "报警", colloquial: "打 110", ask: "需要报警吗？"),
            Term(id: "e03", category: "紧急", standard: "手语翻译", colloquial: "手语", ask: "需要手语翻译吗？"),
            Term(id: "e04", category: "紧急", standard: "现场工作人员", colloquial: "工作人员", ask: "要帮你找工作人员吗？"),
            Term(id: "e05", category: "紧急", standard: "联系人", colloquial: "家人电话", ask: "要联系哪位家人？"),
            Term(id: "e06", category: "紧急", standard: "地址", colloquial: "在哪里", ask: "你现在在哪里？"),
            Term(id: "e07", category: "紧急", standard: "陪同", colloquial: "有人陪", ask: "有人陪着你吗？"),
            Term(id: "e08", category: "紧急", standard: "救护车", colloquial: "120", ask: "救护车到了吗？"),
            Term(id: "e09", category: "紧急", standard: "绿色通道", colloquial: "优先通道", ask: "需要走绿色通道吗？"),
            Term(id: "e10", category: "紧急", standard: "听力障碍", colloquial: "听不见", ask: "请用文字沟通好吗？")
        ]
    )
}
