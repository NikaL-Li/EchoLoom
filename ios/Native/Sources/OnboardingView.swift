import SwiftUI

/// All previews are local, silent examples. They never write orders, phrases or voice preferences.
struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var isReplay = false
    let onFinish: () -> Void
    @State private var page = 0
    @State private var replied = false
    @State private var routeExample = false
    @State private var visitedSettings = false

    private let names = ["面对面沟通", "日常工具", "电话辅助"]

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView(selection: $page) {
                guidePage(0, title: "你打字，译声帮你说", subtitle: "在首页点「面对面沟通」。输入一句话就能播报，也可以开启转写，读对方的回答。") {
                    conversationPreview
                    featureNote("想安静地聊？", detail: "首页点「双方打字」，把手机递给对方，轮流输入就好，不需要麦克风。", icon: "keyboard")
                }.tag(0)
                guidePage(1, title: "出门前，把要说的话备好", subtitle: "在首页风景上向上滑，或点「更多功能」。选一个场景，把地址、电话和想问的问题放在一起。") {
                    deliveryPreview
                    featureNote("常说的话，不必每次重打", detail: "在「常用语」里添加自己的句子，按习惯排序，聊天时点一下就能播报。", icon: "quote.bubble")
                }.tag(1)
                guidePage(2, title: "打电话，也能看着聊", subtitle: "看全页，再跟着画面找到要点的按钮。") {
                    LiveCaptionWalkthrough(visible: page == 2)
                    Text("实时字幕显示对方的话；播报你的文字需另开「通话中添加音频」。字幕可用性取决于机型、语言和地区。")
                        .font(.footnote).foregroundStyle(Color.ylctTextSecondary)
                }.tag(2)
            }.tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background {
            ZStack(alignment: .topTrailing) {
                Color.ylctCanvas
                Circle().fill(Color.ylctMint.opacity(0.10)).frame(width: 260, height: 260)
                    .blur(radius: 55).offset(x: 100, y: -80)
            }.ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "bubble.left.and.bubble.right.fill").font(.title3).foregroundStyle(Color.ylctBlue)
            Text("译声").font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctText)
            Spacer()
            Button(isReplay ? "关闭" : "先逛逛", action: onFinish)
                .font(.subheadline.weight(.medium)).foregroundStyle(Color.ylctTextSecondary)
                .frame(minWidth: 64, minHeight: 44).accessibilityIdentifier("onboarding.skip")
        }.padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 6)
    }

    private func guidePage<Content: View>(_ index: Int, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("0\(index + 1)  /  \(names[index])")
                        .font(.caption.weight(.bold)).tracking(1).foregroundStyle(Color.ylctBlue)
                    Text(title).font(.system(size: 30, weight: .bold, design: .rounded))
                        .lineSpacing(4).foregroundStyle(Color.ylctText).fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader).accessibilityIdentifier("onboarding.title.\(index)")
                    Text(subtitle).font(.body).foregroundStyle(Color.ylctTextSecondary).lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content()
            }.padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 12)
        }.accessibilityIdentifier("onboarding.page.\(index)")
    }

    private var conversationPreview: some View {
        VStack(alignment: .leading, spacing: 13) {
            previewLabel("面对面", icon: "person.2.wave.2.fill")
            VStack(alignment: .leading, spacing: 8) {
                Label("对方 · 语音转文字", systemImage: "waveform").font(.caption.weight(.medium)).foregroundStyle(Color.ylctTextSecondary)
                Text("您好，请问您预约了几点？")
                    .font(.body.weight(.medium)).foregroundStyle(Color.ylctText).padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.ylctSurfaceSoft, in: RoundedRectangle(cornerRadius: 18))
            }
            HStack {
                Spacer(minLength: 32)
                VStack(alignment: .trailing, spacing: 8) {
                    Text("我 · 文字回复").font(.caption2.weight(.medium)).foregroundStyle(Color.ylctTextSecondary)
                    Text(replied ? "我约了下午三点，谢谢。" : "在这里，输入想说的话…")
                        .font(.body.weight(.medium)).foregroundStyle(replied ? .white : Color.ylctBlue)
                        .padding(15).background(replied ? Color.ylctAction : Color.ylctBlue.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityIdentifier("onboarding.demoReply")
                }
            }
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { replied.toggle() }
            } label: {
                Label(replied ? "再试一次" : "试试文字回复", systemImage: replied ? "arrow.counterclockwise" : "paperplane.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctBlue)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }.buttonStyle(PressStyle()).accessibilityIdentifier("onboarding.tryReply")
            Text("无声演示 · 不会录音或播放声音")
                .font(.caption).foregroundStyle(Color.ylctTextSecondary).frame(maxWidth: .infinity)
        }.ylctCard(radius: 28, padding: 18)
    }

    private var deliveryPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            previewLabel("窗口办事", icon: "building.2")
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.and.ellipse").font(.title2).foregroundStyle(Color.ylctMint)
                    .frame(width: 46, height: 46).background(Color.ylctMint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text("社区服务中心").font(.headline).foregroundStyle(Color.ylctText)
                    Text("咨询窗口 · 预约编号 A026").font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                }
            }
            HStack(spacing: 12) {
                demoAction("导航", icon: "location.fill", selected: routeExample) { routeExample = true }
                demoAction("联系对方", icon: "phone.fill", selected: !routeExample) { routeExample = false }
            }
            Text(routeExample ? "先核对目的地，再选择地图导航。" : "完整号码可快捷拨号，拨出前先确认。")
                .font(.subheadline).foregroundStyle(Color.ylctTextSecondary).frame(minHeight: 26, alignment: .topLeading)
                .accessibilityIdentifier("onboarding.deliveryHint")
            Divider()
            HStack(spacing: 9) {
                Image(systemName: "text.bubble.fill").foregroundStyle(Color.ylctBlue)
                Text("带着问题进入沟通").font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctText)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right").foregroundStyle(Color.ylctTextSecondary)
            }.padding(.vertical, 5)
            Text("示例操作 · 不会导航或拨打电话").font(.caption).foregroundStyle(Color.ylctTextSecondary)
        }.ylctCard(radius: 28, padding: 18)
    }

    private func previewLabel(_ title: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctText)
            Spacer()
            Text("示例").font(.caption2.weight(.medium)).foregroundStyle(Color.ylctTextSecondary)
                .padding(.horizontal, 9).padding(.vertical, 5).background(Color.ylctSurfaceSoft, in: Capsule())
        }
    }

    private func demoAction(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.subheadline.weight(.semibold)).foregroundStyle(selected ? Color.ylctBlue : Color.ylctTextSecondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(selected ? Color.ylctBlue.opacity(0.10) : Color.ylctSurfaceSoft, in: RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(PressStyle()).accessibilityIdentifier(title == "导航" ? "onboarding.demoNavigate" : "onboarding.demoCall")
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func featureNote(_ title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color.ylctMint).padding(.top, 2)
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ylctText)
                Text(detail).font(.subheadline).foregroundStyle(Color.ylctTextSecondary).lineSpacing(3)
            }
        }.padding(.horizontal, 2)
    }

    private var footer: some View {
        VStack(spacing: 9) {
            HStack(spacing: 4) {
                ForEach(names.indices, id: \.self) { index in
                    Button { changePage(index) } label: {
                        Capsule().fill(page == index ? Color.ylctAction : Color.ylctStroke)
                            .frame(width: page == index ? 26 : 8, height: 6).frame(width: 44, height: 36)
                    }.accessibilityLabel("第 \(index + 1) 页，\(names[index])")
                        .accessibilityIdentifier("onboarding.step.\(index)")
                        .accessibilityAddTraits(page == index ? [.isSelected] : [])
                }
            }
            if page == 2 {
                CaptionSettingsAction(visited: $visitedSettings)
                Button(visitedSettings ? "完成引导" : "下次再说", action: onFinish)
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("onboarding.next")
            } else {
                HStack(spacing: 12) {
                    if page > 0 {
                        Button { changePage(page - 1) } label: {
                            Image(systemName: "arrow.left").frame(width: 52, height: 52).ylctLens(17, touch: true)
                        }.accessibilityLabel("上一步").accessibilityIdentifier("onboarding.back")
                    }
                    PrimaryButton(title: "继续", systemImage: "arrow.right") { changePage(page + 1) }
                        .accessibilityIdentifier("onboarding.next")
                }
            }
            if page != 2 { Text("随时在「我的 → 重看使用引导」重新查看")
                .font(.caption2).foregroundStyle(Color.ylctTextSecondary).padding(.top, 3) }
        }.padding(.horizontal, 24).padding(.bottom, 12)
            .ylctDock()
    }

    private func changePage(_ index: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) { page = index }
    }

}
