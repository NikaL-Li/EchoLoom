import SwiftUI
import UIKit

struct SignView: View {
    var showPickupCode = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppState
    @State private var custom = ""
    @State private var edit = false
    @State private var showPickup = false
    @State private var previousIdleDisabled = false
    var body: some View {
        ZStack {
            Color(hex: 0x07121F).ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Label("请看这里", systemImage: "hand.raised.fill").font(.headline).foregroundStyle(Color(hex: 0x9AC4FF))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                            .frame(width: 48, height: 48).ylctGlass(Circle(), tint: .ylctInk, solid: .ylctInk, touch: true)
                    }.accessibilityLabel("关闭大字牌")
                }
                Spacer(minLength: 12)
                if showPickup {
                    Text(app.pickup.merchant.isEmpty ? "我来取餐" : app.pickup.merchant).font(.title2.bold()).foregroundStyle(.white.opacity(0.8))
                    Text(app.pickup.code).font(.system(size: 76, weight: .bold, design: .rounded)).minimumScaleFactor(0.4).lineLimit(2).foregroundStyle(.white)
                    if !app.pickup.phone.isEmpty { Text("手机尾号 \(app.pickup.phone.suffix(4))").font(.title2.bold()).foregroundStyle(.white) }
                } else {
                    Image(systemName: "text.bubble.fill").font(.system(size: 48)).foregroundStyle(Color(hex: 0x9AC4FF)).accessibilityHidden(true)
                    Text(custom.trimmed.isEmpty ? app.universal.data.preferences.communication.displayText : custom.trimmed).font(.system(size: 54, weight: .bold, design: .rounded)).minimumScaleFactor(0.7).foregroundStyle(.white)
                }
                Button { edit = true } label: { Text("编辑展示文字").padding(.horizontal, 18).frame(minHeight: 46).ylctGlass(Capsule(), tint: .ylctInk, solid: .ylctInk, touch: true) }
                    .buttonStyle(.plain)
                    .font(.system(.title2, design: .rounded, weight: .semibold)).foregroundStyle(.white.opacity(0.88)).lineSpacing(8)
                Spacer(minLength: 12)
                if showPickupCode, app.mode == .pickup, !app.pickup.code.isEmpty {
                    Picker("展示内容", selection: $showPickup) {
                        Text("身份说明").tag(false)
                        Text("取餐码").tag(true)
                    }.pickerStyle(.segmented).padding(.bottom, 8).environment(\.colorScheme, .dark)
                }
                Text("展示时保持亮屏 · 点右上角关闭").font(.caption).foregroundStyle(.white.opacity(0.65))
            }.padding(28).multilineTextAlignment(.center)
        }
        .alert("编辑沟通卡", isPresented: $edit) {
            TextField("想展示的话", text: $custom)
            Button("完成") {}
        }
        .statusBarHidden(true)
        .onAppear { previousIdleDisabled = UIApplication.shared.isIdleTimerDisabled; UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = previousIdleDisabled }
    }
}

struct MessageDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var previousIdleDisabled = false
    @State private var flipped = false
    let text: String
    var body: some View {
        ZStack {
            Color(hex: 0x07121F).ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Label("我想说", systemImage: "text.bubble.fill").font(.headline).foregroundStyle(Color(hex: 0x9AC4FF))
                    Spacer()
                    Button { flipped.toggle() } label: { Text("翻转").padding(.horizontal, 12).frame(minHeight: 44).ylctGlass(Capsule(), tint: .ylctInk, solid: .ylctInk, touch: true) }.foregroundStyle(.white)
                    Button { dismiss() } label: { Text("返回对话").padding(.horizontal, 12).frame(minHeight: 48).ylctGlass(Capsule(), tint: .ylctInk, solid: .ylctInk, touch: true) }.font(.headline).foregroundStyle(.white)
                }
                ScrollView {
                    Text(text).font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .lineSpacing(12).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 32).textSelection(.enabled)
                }
                .rotationEffect(.degrees(flipped ? 180 : 0))
                Text("保持亮屏 · 长文字可向上滑动").font(.caption).foregroundStyle(.white.opacity(0.7))
            }.padding(26)
        }.statusBarHidden(true)
            .onAppear { previousIdleDisabled = UIApplication.shared.isIdleTimerDisabled; UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = previousIdleDisabled }
    }
}
