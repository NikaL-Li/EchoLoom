import SwiftUI
import Foundation

struct HomeView: View {
    @Environment(YZAppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
                header.rise(appeared: appeared, index: 0, reduceMotion: reduceMotion)
                Group {
                    if YZTheme.highContrast {
                        YZCard {
                            Text("让每句话，都被听见。")
                                .font(YZTheme.fontHero)
                                .foregroundStyle(YZTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        HeroCarousel()
                    }
                }
                .rise(appeared: appeared, index: 1, reduceMotion: reduceMotion)
                actionSection.rise(appeared: appeared, index: 2, reduceMotion: reduceMotion)
                moreCard.rise(appeared: appeared, index: 3, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, YZTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, YZTheme.tabBottomInset)
        }
        .scrollIndicators(.hidden)
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
                Spacer(minLength: 0)
                TodayCard(count: appState.todaySessionCount)
            }

            VStack(alignment: .leading, spacing: 12) {
                headerText
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    TodayCard(count: appState.todaySessionCount)
                }
            }
        }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(YZTheme.fontCaption)
                .foregroundStyle(YZTheme.ink2)
            Text("译诊")
                .font(YZTheme.fontPageTitle)
                .foregroundStyle(YZTheme.ink)
        }
    }

    private var sectionTitle: some View {
        Text("现在要做什么？")
            .font(YZTheme.fontSectionTitle)
            .foregroundStyle(YZTheme.ink)
    }

    private var sectionHint: some View {
        Text("选好就开始")
            .font(YZTheme.fontCaption)
            .foregroundStyle(YZTheme.ink3)
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: YZTheme.gapGroup) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    sectionTitle
                    Spacer(minLength: 0)
                    sectionHint
                }
                VStack(alignment: .leading, spacing: 4) {
                    sectionTitle
                    sectionHint
                }
            }
            HStack(spacing: YZTheme.gapInner) {
                HomeActionCard(
                    title: "开始对话",
                    subtitle: "听对方说 · 你说给他听",
                    icon: "mic",
                    background: YZTheme.blueFill
                ) {
                    appState.startTalk()
                }
                HomeActionCard(
                    title: "一键亮牌",
                    subtitle: "不方便说话时，亮给他们看",
                    icon: "rectangle.portrait",
                    background: YZTheme.greenFill
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
                    .font(YZTheme.fontTag)
                    .foregroundStyle(YZTheme.ink2)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(YZTheme.highContrast ? .black : .white)
                    .frame(width: 32, height: 32)
                    .background(YZTheme.greenFill, in: Circle())
                    .overlay {
                        if YZTheme.highContrast {
                            Circle().stroke(Color.black, lineWidth: 2)
                        }
                    }
                    .accessibilityHidden(true)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(count)")
                    .font(.system(size: 28 * min(YZTheme.scale, 1.3), weight: .bold))
                    .foregroundStyle(YZTheme.ink)
                Text("次")
                    .font(YZTheme.fontTag)
                    .foregroundStyle(YZTheme.ink3)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 112 * min(YZTheme.scale, 1.35), alignment: .leading)
        .background(YZTheme.card, in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous))
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
    let title: String
    let subtitle: String
    let icon: String
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(YZTheme.highContrast ? .black : .white)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            YZTheme.highContrast ? .black : .white.opacity(0.95)
                        )
                }
                Spacer(minLength: 8)
                Text(title)
                    .font(.system(size: 20 * min(YZTheme.scale, 1.15), weight: .bold))
                    .foregroundStyle(YZTheme.highContrast ? .black : .white)
                Text(subtitle)
                    .font(.system(size: 12 * min(YZTheme.scale, 1.15), weight: .regular))
                    .foregroundStyle(
                        YZTheme.highContrast ? .black : .white.opacity(0.78)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, YZTheme.gapInner)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140 * min(YZTheme.scale, 1.15))
            .background(background, in: RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous))
            .overlay {
                if YZTheme.highContrast {
                    RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                        .stroke(Color.black, lineWidth: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HomeActionCardStyle())
        .accessibilityLabel("\(title)：\(subtitle)")
    }
}

private struct HomeActionCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
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

#Preview {
    HomeView()
        .background(YZTheme.bg)
        .environment(YZAppState.preview)
}