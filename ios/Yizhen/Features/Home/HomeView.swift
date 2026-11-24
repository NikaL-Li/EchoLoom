import SwiftUI
import Foundation

struct HomeView: View {
    @Environment(YZAppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    init() {}


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
                header
                    .rise(appeared: appeared, index: 0, reduceMotion: reduceMotion)
                HeroCarousel()
                    .rise(appeared: appeared, index: 1, reduceMotion: reduceMotion)
                actionSection
                    .rise(appeared: appeared, index: 2, reduceMotion: reduceMotion)
                moreCard
                    .rise(appeared: appeared, index: 3, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, YZTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, YZTheme.tabBottomInset)
            .yzContentWidth()
        }
        .scrollIndicators(.hidden)
        .background(YZTheme.bg)
        .onAppear { appeared = true }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let prefix = (5..<11).contains(hour) ? "早上好"
            : ((11..<18).contains(hour) ? "下午好" : "晚上好")
        return prefix + "，今天也辛苦了"
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                headerText
                Spacer(minLength: 8)
                TodayCard(count: appState.todaySessionCount)
            }

            VStack(alignment: .leading, spacing: 10) {
                headerText
                HStack {
                    TodayCard(count: appState.todaySessionCount)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(YZTheme.fontCaption)
                .foregroundStyle(YZTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
            Text("译诊")
                .font(YZTheme.fontPageTitle)
                .foregroundStyle(YZTheme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("现在要做什么？")
                    .font(YZTheme.fontSectionTitle)
                    .foregroundStyle(YZTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text("选好就开始")
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(YZTheme.ink3)
                    .lineLimit(1)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: YZTheme.gapInner)],
                spacing: YZTheme.gapInner
            ) {
                HomeActionCard(
                    title: "开始对话",
                    subtitle: "听对方说 · 你说给他听",
                    icon: "mic",
                    tone: .blue
                ) {
                    appState.startTalk()
                }

                HomeActionCard(
                    title: "一键亮牌",
                    subtitle: "不方便说话时，亮给他们看",
                    icon: "rectangle.portrait",
                    tone: .green
                ) {
                    appState.showEmergencySign()
                }
            }
        }
    }

    private var moreCard: some View {
        YZCard(padding: 0) {
            VStack(spacing: 0) {
                YZListRow(
                    icon: "person.2",
                    title: "面对面模式",
                    subtitle: "上下分屏，各看一边"
                ) {
                    appState.startTalk(faceToFace: true)
                }

                Divider()
                    .overlay(YZTheme.line)
                    .padding(.leading, 68)

                YZListRow(
                    icon: "text.bubble",
                    title: "我的常用语",
                    subtitle: "当前环节的常用句子",
                    iconColor: YZTheme.green,
                    iconBackground: YZTheme.greenSoft,
                    trailingText: "\(appState.phraseCount) 条"
                ) {
                    appState.openPhrases()
                }
            }
        }
    }
}

private struct TodayCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 4) {
                Text("今日对话")
                    .font(YZTheme.font(size: 11, textStyle: .caption2, maxSize: 15))
                    .foregroundStyle(YZTheme.ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(YZTheme.highContrast ? .black : .white)
                    .frame(width: 28, height: 28)
                    .background(YZTheme.greenFill, in: Circle())
                    .overlay {
                        if YZTheme.highContrast {
                            Circle().stroke(Color.black, lineWidth: 1.5)
                        }
                    }
                    .accessibilityHidden(true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(count)")
                    .font(.system(size: 28 * min(YZTheme.scale, 1.5), weight: .bold))
                    .foregroundStyle(YZTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("次")
                    .font(YZTheme.font(size: 12, textStyle: .caption, maxSize: 17))
                    .foregroundStyle(YZTheme.ink3)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 112, alignment: .leading)
        .background(
            YZTheme.card,
            in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
        )
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
        .yzCardShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今日对话 \(count) 次")
    }
}

private struct HomeActionCard: View {
    enum Tone {
        case blue
        case green
    }

    let title: String
    let subtitle: String
    let icon: String
    let tone: Tone
    let action: () -> Void

    private var background: Color {
        if YZTheme.highContrast { return .white }
        return tone == .blue ? Color(hex: 0x1B41C8) : Color(hex: 0x12796B)
    }

    private var foreground: Color {
        YZTheme.highContrast ? .black : .white
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(foreground)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(foreground.opacity(0.95))
                        .accessibilityHidden(true)
                }

                Spacer(minLength: 12)

                Text(title)
                    .font(YZTheme.font(size: 20, weight: .bold, textStyle: .title3, maxSize: 30))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(YZTheme.font(size: 12, textStyle: .caption, maxSize: 18))
                    .foregroundStyle(foreground.opacity(0.8))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, YZTheme.gapInner)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(
                background,
                in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
            )
            .overlay {
                if YZTheme.highContrast {
                    RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                        .stroke(Color.black, lineWidth: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(YZPressButtonStyle())
        .accessibilityLabel("\(title)：\(subtitle)")
    }
}

private struct RiseIn: ViewModifier {
    let appeared: Bool
    let index: Int
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.25).delay(Double(index) * 0.04),
                value: appeared
            )
    }
}

private extension View {
    func rise(appeared: Bool, index: Int, reduceMotion: Bool) -> some View {
        modifier(RiseIn(appeared: appeared, index: index, reduceMotion: reduceMotion))
    }
}
