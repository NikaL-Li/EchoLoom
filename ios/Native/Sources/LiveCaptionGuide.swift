import SwiftUI

private struct CaptionSlide {
    let title, instruction, source: String
    // Coordinates are in the 402 × 874 point portrait, never in the presentation view.
    let row: CGRect
    let target: CGRect
    static let all = [
        Self(title: "进入无障碍设置", instruction: "点「无障碍」。部分系统称为「辅助功能」。", source: "模拟器截图", row: CGRect(x: 16, y: 345.7, width: 370, height: 52.3), target: CGRect(x: 16, y: 345.7, width: 370, height: 52.3)),
        Self(title: "找到「实时字幕」", instruction: "向下找到「听觉」，点「实时字幕」。它与「字幕与隐藏式字幕」是两项设置。", source: "截图合成示意", row: CGRect(x: 16, y: 530, width: 370, height: 53), target: CGRect(x: 16, y: 530, width: 370, height: 53)),
        Self(title: "打开实时字幕开关", instruction: "打开右侧开关；如果已经打开，直接看下一步。", source: "设置页示意", row: CGRect(x: 16, y: 206, width: 370, height: 58), target: CGRect(x: 306, y: 213, width: 69, height: 44)),
        Self(title: "选择「iPhone 音频」", instruction: "通话时展开字幕浮窗，选「iPhone 音频」。选「麦克风」识别的是身边的声音。", source: "通话浮窗示意", row: CGRect(x: 30, y: 548, width: 342, height: 74), target: CGRect(x: 174, y: 556, width: 192, height: 57))
    ]
}

private struct CaptionCamera: View {
    let bitmap: UIImage
    let row: CGRect
    let target: CGRect
    let seconds: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let fit = min((w - 10) / 402, (h - 10) / 874)
            let close = max(fit, min(w / (row.width + 24), h / (row.height + 64)))
            func clamp(_ value: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
                min(max(value, lo), hi)
            }
            func endOrigin(_ viewport: CGFloat, _ photo: CGFloat, _ center: CGFloat) -> CGFloat {
                let extent = photo * close
                return extent <= viewport ? (viewport - extent) / 2 : clamp(viewport / 2 - center * close, viewport - extent, 0)
            }
            func ease(_ raw: Double) -> CGFloat {
                let t = min(1, max(0, raw)); return t*t*t*(t*(t*6-15)+10)
            }
            // One continuous transform for the image and its target. The ring waits for the camera.
            let mix = ease((seconds - 1.15) / 1.40)
            let scale = fit + (close - fit) * mix
            let ox = (w - 402 * fit) / 2, oy = (h - 874 * fit) / 2
            let x = ox + (endOrigin(w, 402, row.midX) - ox) * mix
            let y = oy + (endOrigin(h, 874, row.midY) - oy) * mix
            ctx.draw(Image(uiImage: bitmap).renderingMode(.original), in: CGRect(x: x, y: y, width: 402 * scale, height: 874 * scale))
            let opacity = ease((seconds - 2.55) / 0.35)
            guard opacity > 0 else { return }
            let rect = CGRect(x: x + target.minX*scale, y: y + target.minY*scale, width: target.width*scale, height: target.height*scale)
            // Frame the whole setting; soften its neighbours without hiding which page this is.
            let rowRect = CGRect(x: x + row.minX*scale, y: y + row.minY*scale,
                                 width: row.width*scale, height: row.height*scale)
            let focusBand = rowRect.insetBy(dx: -4, dy: -5)
            var shade = Path(CGRect(origin: .zero, size: size))
            shade.addRoundedRect(in: focusBand, cornerSize: CGSize(width: 10, height: 10))
            ctx.fill(shade, with: .color(.black.opacity(0.37 * opacity)), style: FillStyle(eoFill: true))
            let outline = Path(roundedRect: rect, cornerRadius: 9)
            ctx.opacity = opacity
            ctx.stroke(outline, with: .color(.black.opacity(0.85)), lineWidth: 6)
            let mint = Color(red: 0.50, green: 0.94, blue: 0.85)
            ctx.stroke(outline, with: .color(mint), lineWidth: 3)
            let badge = CGRect(x: rect.minX + 4, y: rect.minY - 20, width: 54, height: 22)
            ctx.fill(Path(roundedRect: badge, cornerRadius: 8), with: .color(mint))
            ctx.draw(Text("点这里").font(.caption2.bold()).foregroundStyle(.black), at: CGPoint(x: badge.midX, y: badge.midY))
        }
        .background(Color(red: 0.08, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityHidden(true)
    }
}

private struct CaptionPlayer: View {
    let index: Int
    let visible: Bool
    let large: Bool
    let expand: () -> Void
    let manualTransport: () -> Void
    let finished: () -> Void
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var bitmap: UIImage?
    @State private var loadFailed = false
    @State private var elapsed: Double = 0
    @State private var anchor: Date?
    @State private var paused = false
    private let duration = 3.05
    private var still: Bool { reduced || voiceOver }
    private var active: Bool { visible && phase == .active && bitmap != nil && !still && !paused && elapsed < duration }
    private var atEnd: Bool { elapsed >= duration }
    private var action: String { still ? (atEnd ? "看全页" : "查看按钮") : (atEnd ? "重播" : (paused ? "继续" : "暂停")) }
    private var slide: CaptionSlide { CaptionSlide.all[index] }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let bitmap {
                    // Inactive pages, paused demos and the final frame consume no animation ticks.
                    TimelineView(.animation(paused: anchor == nil)) { timeline in
                        CaptionCamera(bitmap: bitmap, row: slide.row, target: slide.target,
                                      seconds: elapsed + (anchor.map { max(0, timeline.date.timeIntervalSince($0)) } ?? 0))
                    }
                } else if loadFailed {
                    ContentUnavailableView("图片未能载入", systemImage: "photo", description: Text(slide.instruction))
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(slide.title)
            .accessibilityValue(atEnd ? "已标出按钮" : "查看页面")
            .accessibilityIdentifier("captions.viewport")
            HStack {
                Text(slide.source).font(.caption).foregroundStyle(Color.ylctTextSecondary)
                Spacer()
                Button(action: transport) {
                    Label(action, systemImage: still ? "viewfinder" : atEnd ? "arrow.counterclockwise" : paused ? "play.fill" : "pause.fill")
                }.accessibilityIdentifier("captions.transport")
                if !large {
                    Button(action: expand) { Label("全屏", systemImage: "arrow.up.left.and.arrow.down.right") }
                        .accessibilityIdentifier("captions.enlarge")
                }
            }.font(.subheadline.weight(.semibold)).buttonStyle(.borderless)
                .controlSize(.regular).frame(minHeight: 44)
        }
        .task {
            let step = index + 1
            let loaded = await Task.detached(priority: .userInitiated) {
                Bundle.main.url(forResource: "ys-caption-step-\(step)", withExtension: "png")
                    .flatMap { UIImage(contentsOfFile: $0.path)?.preparingForDisplay() }
            }.value
            guard !Task.isCancelled else { return }
            bitmap = loaded; loadFailed = loaded == nil
        }
        .onChange(of: active, initial: true) { _, run in
            if run { anchor = .now } else { freeze() }
        }
        .onDisappear { freeze() }
        .task(id: anchor) {
            guard let start = anchor else { return }
            do { try await Task.sleep(for: .seconds(max(0, duration - elapsed))) } catch { return }
            guard start == anchor else { return }
            elapsed = duration; anchor = nil; finished()
        }
    }
    private func freeze() {
        if let start = anchor { elapsed = min(duration, elapsed + max(0, Date().timeIntervalSince(start))); anchor = nil }
    }
    private func transport() {
        manualTransport()
        if still { elapsed = atEnd ? 0 : duration; return }
        if atEnd { elapsed = 0; paused = false }
        else if paused { paused = false }
        else { freeze(); paused = true }
    }
}

struct LiveCaptionWalkthrough: View {
    var visible = true
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var index = 0
    @State private var generation = 0
    @State private var expanded = false
    @State private var continuous = false
    @State private var landed = false
    private var slide: CaptionSlide { CaptionSlide.all[index] }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            player(false).frame(height: 255)
            description
            controls(false)
        }.frame(maxWidth: .infinity, alignment: .leading).ylctCard(padding: 12)
            .accessibilityHidden(expanded)
            .fullScreenCover(isPresented: $expanded) {
                NavigationStack {
                    ViewThatFits(in: .vertical) {
                        VStack(alignment: .leading, spacing: 12) {
                            player(true).frame(minHeight: 240); description; controls(true)
                        }
                        ScrollView { VStack(alignment: .leading, spacing: 12) {
                            player(true).frame(height: 300); description; controls(true)
                        } }
                    }.padding(.horizontal, 16).padding(.bottom, 8)
                        .background(YLCTBackground()).navigationTitle("查看标注图").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { expanded = false }.accessibilityIdentifier("captions.closeImage") } }
                }
            }
            .task(id: landed && continuous && visible && phase == .active && !reduced && !voiceOver) {
                guard landed && continuous && visible && phase == .active && !reduced && !voiceOver else { return }
                do { try await Task.sleep(for: .seconds(2.2)) } catch { return }
                guard index < 3 else { continuous = false; return }
                go(index+1, manual: false)
            }
    }
    private func player(_ large: Bool) -> some View {
        CaptionPlayer(index: index, visible: visible && (expanded == large), large: large, expand: {
            continuous = false; landed = false; expanded = true
        }, manualTransport: { continuous = false; landed = false }, finished: { landed = true })
            .id(generation)
    }
    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(index+1)/4  ·  \(slide.title)").font(.headline).accessibilityIdentifier("captions.title")
            Text(slide.instruction).font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    private func controls(_ detail: Bool) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { i in
                Button { go(i) } label: {
                    Text("\(i+1)").font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(i == index ? .white : Color.ylctText)
                        .frame(width: 30, height: 30).background(i == index ? Color.ylctAction : Color.ylctSurfaceSoft, in: Circle())
                        .frame(minWidth: 42, minHeight: 44)
                }.buttonStyle(.plain).accessibilityLabel("第 \(i+1) 步，\(CaptionSlide.all[i].title)")
                    .accessibilityAddTraits(i == index ? .isSelected : [])
                    .accessibilityIdentifier((detail ? "captions.detail.step." : "captions.step.") + String(i))
            }
            Spacer(minLength: 0)
            if !reduced && !voiceOver {
                Button(continuous ? "停播" : "连播") {
                    if !continuous { go(index == 3 ? 0 : index, manual: false) }
                    continuous.toggle()
                }.font(.footnote).frame(minHeight: 44)
            }
            Button(index == 3 ? "从头看" : "下一步") { go((index+1)%4) }
                .font(.subheadline.bold()).frame(minHeight: 44)
                .accessibilityIdentifier(detail ? "captions.detail.advance" : "captions.advance")
        }
    }
    private func go(_ i: Int, manual: Bool = true) {
        if manual { continuous = false }
        landed = false; index = i; generation += 1
    }
}

struct CaptionSettingsAction: View {
    @Environment(\.openURL) private var openURL
    @State private var failed = false
    @Binding var visited: Bool
    var body: some View {
        VStack(spacing: 7) {
            PrimaryButton(title: visited ? "再次打开设置" : "立即设置", systemImage: "arrow.up.forward.app") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { failed = true; return }
                openURL(url) { accepted in
                    failed = !accepted
                    if accepted { visited = true }
                }
            }.accessibilityIdentifier("captions.settings")
            Text(failed ? "未能打开设置。请手动打开 iPhone「设置」，搜索「实时字幕」。" : "在设置首页搜索「实时字幕」；若停在译声设置，请先返回。")
                .font(.footnote).foregroundStyle(Color.ylctTextSecondary).multilineTextAlignment(.center)
        }
    }
}

struct LiveCaptionGuide: View {
    @State private var visited = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("在电话里看见对方的话").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text("iPhone 会把通话声音转成系统浮窗里的文字。字幕不会存入译声的聊天记录。")
                LiveCaptionWalkthrough()
                Text("找不到「实时字幕」？这项功能受机型、语言和地区限制。")
                    .font(.footnote).foregroundStyle(Color.ylctTextSecondary)
                CaptionSettingsAction(visited: $visited)
            }.frame(maxWidth: 560).padding(20).frame(maxWidth: .infinity)
        }.background(YLCTBackground()).navigationTitle("系统实时字幕").navigationBarTitleDisplayMode(.inline)
    }
}
