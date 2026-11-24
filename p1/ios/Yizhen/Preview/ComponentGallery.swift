import SwiftUI

struct ComponentGalleryView: View {
    @State private var lightToast: String?
    @State private var darkToast: String?
    @State private var isOn = true
    @State private var segment = 1

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                gallery(for: .light, toast: $lightToast)
                gallery(for: .dark, toast: $darkToast)
            }
            .padding(16)
        }
        .background(Color(hex: 0xE9EDF4))
    }

    private func gallery(for scheme: ColorScheme, toast: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            YZPageTitle(
                title: scheme == .light ? "浅色" : "深色",
                subtitle: "组件总览 · 圆角 24 / 间距 12 / 页边 16"
            )

            YZSectionTitle(title: "卡片")
            YZCard {
                Text("白卡片：圆角 24、内边距 16、阴影 0 2 12。")
                    .font(YZTheme.fontBody)
                    .foregroundStyle(YZTheme.ink2)
            }

            YZSectionTitle(title: "主按钮")
            YZPrimaryButton(title: "开始对话") {}

            YZSectionTitle(title: "胶囊按钮")
            HStack(spacing: 8) {
                YZPillButton(title: "未选中") {}
                YZPillButton(title: "已选中", isSelected: true) {}
                YZPillButton(title: "小胶囊", size: .small) {}
            }

            YZSectionTitle(title: "列表行")
            YZCard(padding: 0) {
                YZListRow(
                    icon: "person.2",
                    title: "面对面模式",
                    subtitle: "上下分屏，各看一边",
                    action: {}
                )
                Divider()
                    .overlay(YZTheme.line)
                    .padding(.leading, 68)
                YZListRow(
                    icon: "text.bubble",
                    title: "我的常用语",
                    subtitle: "当前环节的常用句子",
                    iconColor: YZTheme.green,
                    iconBackground: YZTheme.greenSoft,
                    trailingText: "6 条",
                    action: {}
                )
            }

            YZSectionTitle(title: "开关行")
            YZCard(padding: 0) {
                YZSwitchRow(
                    title: "全程用文字",
                    subtitle: "打开后不调用麦克风",
                    isOn: $isOn
                )
            }

            YZSectionTitle(title: "三段式分段")
            YZSegmented(options: ["18", "24", "30"], selection: $segment)

            YZSectionTitle(title: "轻提示")
            YZPillButton(title: "点我弹提示") {
                toast.wrappedValue = "已保存"
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(YZTheme.bg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .environment(\.colorScheme, scheme)
        .yzToast(toast)
    }
}

#Preview {
    ComponentGalleryView()
}