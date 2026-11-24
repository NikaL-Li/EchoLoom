import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState
    @State private var showPreferences = false
    @State private var showGuide = false
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var position = ScrollPosition(edge: .top)
    @State private var offset: CGFloat = 0
    @State private var isMoving = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let top = proxy.safeAreaInsets.top
                let bottom = proxy.safeAreaInsets.bottom
                let height = proxy.size.height + top + bottom
                let width = proxy.size.width
                let cardHeight: CGFloat = typeSize.isAccessibilitySize ? 310 : 211
                let topGap = top + 10
                let quickHeight: CGFloat = typeSize.isAccessibilitySize ? 70 : 48
                let travel = max(1, height - topGap - cardHeight - quickHeight - 12)
                let distance = min(travel, max(0, offset))
                let fraction = distance / travel
                let p = reduced ? (fraction < 0.5 ? 0.0 : 1.0) : fraction
                let cue = 48 + bottom
                let overlap = quickHeight + cue
                let inset = max(18, (width - 590) / 2)
                let photoHeight = height - distance - (topGap + quickHeight + 12) * p
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // The hero keeps its identity and bottom anchor. Scrolling
                            // shrinks the photograph while keeping its top in view.
                            VStack(spacing: 0) {
                                HomeScenery(outdoors: app.outdoors, preference: app.universal.data.preferences.communication,
                                            height: max(cardHeight, photoHeight), corner: 24 * p,
                                            topPadding: (top + 4) * (1 - p) + 8 * p,
                                            bottomPadding: 16 + overlap * (1 - p),
                                            allowsRotation: app.tab == .home && !app.showDialogue && !app.showSign && !showPreferences && !showGuide && (fraction < 0.01 || fraction > 0.99),
                                            start: { app.openGeneralConversation(startCaptions: app.universal.data.preferences.communication == .captions) },
                                            configure: { showPreferences = true })
                                    .padding(.horizontal, inset * p)
                                Color.clear.frame(height: (quickHeight + 12) * p).accessibilityHidden(true)
                            }.overlay(alignment: .bottom) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 10) {
                                        quickAction("双方打字", icon: "text.bubble.fill", immersive: p < 0.5) { app.openGeneralConversation(style: .textOnly) }
                                            .accessibilityIdentifier("universal.text-only")
                                        quickAction("电话辅助", icon: "phone.fill", immersive: p < 0.5) { app.openGeneralConversation(phone: true) }
                                            .accessibilityIdentifier("universal.phone")
                                    }.ylctGroup().frame(height: quickHeight).padding(.horizontal, inset)

                                    Button { move(to: travel) } label: {
                                        Label("上滑查看更多功能", systemImage: "chevron.up").font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                                    }.buttonStyle(.plain).accessibilityLabel("更多功能").accessibilityIdentifier("home.more")
                                        .frame(height: cue * (1 - p), alignment: .top).clipped().opacity(1 - p)
                                        .allowsHitTesting(fraction < 0.25).accessibilityHidden(fraction >= 0.25)
                                }
                            }.frame(height: height, alignment: .bottom)
                            tools {
                                move(to: 0)
                            }.padding(.horizontal, inset).padding(.top, 18)
                                .frame(minHeight: travel, alignment: .top)
                                .allowsHitTesting(!isMoving && fraction > 0.93)
                                .accessibilityHidden(fraction < 0.93)
                        }
                    }
                    .refreshable { await app.outdoors.refresh(force: true) }
                    .scrollIndicators(.hidden)
                    .onScrollPhaseChange { _, phase in
                        isMoving = phase == .interacting || phase == .decelerating || phase == .animating
                    }
                    .scrollPosition($position)
                    .scrollTargetBehavior(HomeSnap(distance: travel))
                    .onScrollGeometryChange(for: CGFloat.self) { g in
                        min(travel, max(0, (g.contentOffset.y + g.contentInsets.top).rounded()))
                    } action: { _, new in offset = new }
                    if fraction > 0.93 && app.tab == .home {
                        GlassTabBar(selection: $app.tab)
                            .padding(.horizontal, inset).padding(.bottom, bottom + 6)
                            .transition(.opacity)
                    }
                }.accessibilityHidden(app.tab != .home)
                    .ignoresSafeArea(.container, edges: .vertical)
            }.background(YLCTBackground()).navigationTitle("沟通").toolbar(.hidden, for: .navigationBar)
                .task(id: phase == .active && app.tab == .home) {
                    guard phase == .active, app.tab == .home else { return }
                    await app.outdoors.refresh()
                    while !Task.isCancelled {
                        let wait = max(1, CityAlbum.nextRefresh().timeIntervalSinceNow)
                        do { try await Task.sleep(for: .seconds(wait)) } catch { return }
                        await app.outdoors.refresh(force: true)
                        // Allow the scheduled publisher to finish before retrying.
                        do { try await Task.sleep(for: .seconds(60)) } catch { return }
                        await app.outdoors.refresh()
                    }
                }
                .sheet(isPresented: $showPreferences) { CommunicationPreferencesView() }
                .fullScreenCover(isPresented: $showGuide) { OnboardingView(isReplay: true) { showGuide = false } }
        }.tint(.ylctBlue)
    }

    private func move(to y: CGFloat) {
        withAnimation(reduced ? nil : .easeInOut(duration: 0.42)) { position.scrollTo(y: y) }
    }

    private func quickAction(_ title: String, icon: String, immersive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.subheadline.weight(.semibold))
                .foregroundStyle(immersive ? Color.white : Color.ylctText)
                .frame(maxWidth: .infinity, minHeight: 48)
                .ylctLens(15, tint: immersive ? .ylctInk.opacity(0.68) : nil,
                          solid: immersive ? .ylctInk : .ylctSurface, touch: true)
        }.buttonStyle(PressStyle())
    }

    private func tools(restore: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("更多功能")
                Spacer()
                Button(action: restore) { Label("全屏风景", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.semibold)).frame(minHeight: 44) }
                    .accessibilityIdentifier("home.restore")
            }
            Button { app.openSign() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle").font(.title3)
                    Text("展示沟通卡").font(.headline)
                    Spacer()
                    Text("给对方看").font(.caption)
                    Image(systemName: "chevron.right").font(.caption2)
                }.foregroundStyle(Color.ylctText).padding(.horizontal, 16).frame(minHeight: 54)
                    .ylctLens(16, touch: true)
            }.buttonStyle(PressStyle()).accessibilityIdentifier("universal.card")
            HStack {
                sectionTitle("场景准备")
                Spacer()
                Button("所有场景") { app.tab = .scenes }.font(.subheadline).frame(minHeight: 44)
            }
            HStack(spacing: 8) {
                ForEach(preferredScenes.prefix(3)) { kind in
                    NavigationLink { EverydaySceneEditor(initial: EverydaySceneDraft(kind: kind)) } label: {
                        Label(kind.title, systemImage: kind.icon).font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.ylctText).frame(maxWidth: .infinity, minHeight: 50)
                            .ylctLens(14, touch: true)
                    }.buttonStyle(PressStyle()).accessibilityIdentifier("home.scene.\(kind.rawValue)")
                }
            }.ylctGroup()
            HStack(spacing: 16) {
                NavigationLink { SavedConversationsView() } label: {
                    Label("保存的对话", systemImage: "clock.arrow.circlepath").frame(minHeight: 44)
                }
                Spacer()
                Button { showGuide = true } label: {
                    Label("使用引导", systemImage: "questionmark.circle").frame(minHeight: 44)
                }
            }.font(.subheadline)
        }.padding(.bottom, 100)
    }
    private var preferredScenes: [EverydaySceneKind] {
        let favorites = app.universal.data.favoriteSceneKinds
        return favorites + [.shopping, .travel, .health].filter { !favorites.contains($0) }
    }
    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.title3.bold()).foregroundStyle(Color.ylctText).accessibilityAddTraits(.isHeader)
    }
}

// Preserve normal scrolling below the compact card, but never leave the
// photograph halfway folded when a deliberate swipe ends.
private struct HomeSnap: ScrollTargetBehavior {
    let distance: CGFloat
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let from = context.originalTarget.rect.minY
        let to = target.rect.minY
        guard from < distance + 2 || to < distance else { return }
        if from < 2 && to > 32 { target.rect.origin.y = distance }
        else if from >= distance - 3 && to < distance - 32 { target.rect.origin.y = 0 }
        else if to < distance { target.rect.origin.y = to < distance / 2 ? 0 : distance }
    }
}

// Both crops are decoded once per scene, outside the main thread. Scrolling only blends layers.
private struct CitySceneryImage: View {
    let photo: CityPhoto
    let size: CGSize
    let progress: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduced
    private struct Pair { let key: URL; let portrait, landscape: UIImage }
    @State private var displayed: Pair?
    var body: some View {
        ZStack {
            if let pair = displayed {
                ZStack {
                    layer(pair.portrait)
                    layer(pair.landscape).opacity(min(1, max(0, (progress - 0.50) / 0.45)))
                }.id(pair.key).transition(.opacity)
            } else if let preview = UIImage(named: "LaunchCoast.jpg") {
                layer(preview)
            }
        }.task(id: photo.key) {
            let p = photo.portrait, l = photo.landscape
            let work = Task.detached(priority: .userInitiated) { () -> Pair? in
                guard let a = UIImage(contentsOfFile: p.path)?.preparingForDisplay(),
                      let b = UIImage(contentsOfFile: l.path)?.preparingForDisplay() else { return nil }
                return Pair(key: p, portrait: a, landscape: b)
            }
            let next = await work.value
            guard !Task.isCancelled, let next else { return }
            withAnimation(displayed == nil || reduced ? nil : .easeInOut(duration: 0.35)) { displayed = next }
        }
    }
    private func layer(_ image: UIImage) -> some View {
        Image(uiImage: image).resizable().scaledToFill()
            .frame(width: size.width, height: size.height).clipped()
    }
}

private struct HomeScenery: View {
    @ObservedObject var outdoors: HomeOutdoors
    let preference: CommunicationPreference
    let height: CGFloat, corner: CGFloat, topPadding: CGFloat, bottomPadding: CGFloat
    let allowsRotation: Bool
    let start: () -> Void
    let configure: () -> Void
    @AppStorage("home.landscape.photos") private var usePhotos = true
    @State private var slide = 0
    @State private var showCredit = false
    private var photo: CityPhoto? { usePhotos && !outdoors.photos.isEmpty ? outdoors.photos[slide % outdoors.photos.count] : nil }
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    @AppStorage("home.landscape.rotates") private var rotates = true
    @State private var index = [0, 1, 2][Calendar.current.component(.hour, from: Date()) / 8]
    private let names = ["山间晨雾", "晴日海湾", "暮色沙丘"]
    private let skies: [[Color]] = [
        [.init(red: 0.10, green: 0.30, blue: 0.31), .init(red: 0.48, green: 0.69, blue: 0.52)],
        [.init(red: 0.08, green: 0.28, blue: 0.46), .init(red: 0.42, green: 0.72, blue: 0.78)],
        [.init(red: 0.24, green: 0.17, blue: 0.36), .init(red: 0.80, green: 0.49, blue: 0.48)]]
    private var cycling: Bool { rotates && !reduced && phase == .active && allowsRotation && !showCredit }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(photo == nil ? names[index] : outdoors.photoPlace + " · 城市风景", systemImage: "mountain.2")
                    .font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6)
                    .ylctGlass(Capsule(), tint: .ylctInk.opacity(0.88), solid: .ylctInk)
                Spacer()
                HomeWeatherRow(model: outdoors)
                Menu {
                    Button("换一幅风景", systemImage: "arrow.right") { next() }
                    if photo != nil { Button("照片来源", systemImage: "info.circle") { showCredit = true } }
                    Toggle("使用城市壁纸", isOn: $usePhotos)
                    Toggle("自动轮换", isOn: $rotates)
                } label: {
                    Image(systemName: "photo.on.rectangle.angled").font(.subheadline)
                        .frame(width: 32, height: 32).ylctGlass(Circle(), tint: .ylctInk.opacity(0.88), solid: .ylctInk, touch: true)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("壁纸设置")
            }
            Spacer(minLength: 18)
            Text("面对面沟通").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
            Text(heroSubtitle).font(.subheadline.weight(.medium)).padding(.top, 4)
            HStack(spacing: 12) {
                Button(action: start) {
                    HStack { Text(preference == .captions ? "开始看字幕" : "开始沟通"); Spacer(); Image(systemName: "arrow.right") }
                        .font(.headline).foregroundStyle(Color.ylctInk).padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 50).ylctLens(14, tint: .white.opacity(0.94), solid: .white, touch: true)
                }.buttonStyle(PressStyle()).accessibilityIdentifier("universal.face")
                Button(action: configure) {
                    HStack(spacing: 5) { Text(preference.title); Image(systemName: "chevron.down").font(.caption2.bold()) }
                        .font(.subheadline.weight(.semibold)).padding(.horizontal, 12).frame(minHeight: 46)
                        .ylctLens(13, tint: .ylctInk.opacity(0.85), solid: .ylctInk, touch: true)
                }.buttonStyle(PressStyle()).accessibilityLabel("调整默认模式：" + preference.title).accessibilityIdentifier("universal.preference")
            }.ylctGroup().padding(.top, 16)
        }.foregroundStyle(.white).padding(.horizontal, 18).padding(.top, topPadding).padding(.bottom, bottomPadding)
            .frame(height: height)
            .background {
                GeometryReader { proxy in
                    // Use the live top edge, including rubber-band and refresh insets.
                    // Only the backdrop stretches; buttons and labels keep their size.
                    let pull = corner == 0 ? max(0, proxy.frame(in: .global).minY) : 0
                    let size = CGSize(width: proxy.size.width, height: proxy.size.height + pull)
                    ZStack {
                        if let photo {
                            CitySceneryImage(photo: photo, size: size, progress: corner / 24)
                        } else { artwork(index).id(index).transition(.opacity) }
                        LinearGradient(stops: [.init(color: .black.opacity(0.16), location: 0), .init(color: .black.opacity(0.45 * corner / 24), location: 0.30), .init(color: .black.opacity(0.35 + 0.29 * corner / 24), location: 0.58), .init(color: .black.opacity(0.84), location: 0.88)], startPoint: .top, endPoint: .bottom)
                    }.frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                        .offset(y: -pull)
                }.accessibilityHidden(true).allowsHitTesting(false)
            }
            .sheet(isPresented: $showCredit) {
                if let row = photo?.credit {
                    NavigationStack {
                        List {
                            Section("摄影作品") {
                                Text(row.title); LabeledContent("作者", value: row.author)
                                Text("首页展示同一原片的竖版和横版裁切。")
                            }
                            Section("来源与许可") {
                                if let url = URL(string: row.source), url.scheme == "https" { Link("查看原作", destination: url) }
                                if let url = URL(string: row.licenseURL), url.scheme == "https" { Link(row.license, destination: url) }
                                else { Text(row.license) }
                            }
                        }.navigationTitle("照片来源").toolbar {
                            ToolbarItem(placement: .confirmationAction) { Button("完成") { showCredit = false } }
                        }
                    }.presentationDetents([.medium, .large])
                }
            }
            .onChange(of: usePhotos) { _, enabled in outdoors.setPhotosEnabled(enabled) }
            .task(id: cycling) {
                guard cycling else { return }
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(30)) } catch { return }
                    next()
                }
            }
    }
    private var heroSubtitle: String {
        switch preference {
        case .spokenReply: "我打字，手机帮我说。"
        case .captions: "对方说的话，实时显示为文字。"
        case .textOnly: "把手机递给对方，轮流打字。"
        }
    }
    private func next() {
        withAnimation(reduced ? nil : .easeInOut(duration: 0.75)) { if photo != nil { slide = (slide + 1) % outdoors.photos.count } else { index = (index + 1) % names.count } }
    }
    private func artwork(_ scene: Int) -> some View {
        ZStack {
            LinearGradient(colors: skies[scene], startPoint: .topLeading, endPoint: .bottomTrailing)
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let sun = CGPoint(x: w * [0.72, 0.62, 0.78][scene], y: h * 0.33)
                for (r, a) in [(35.0, 0.07), (25.0, 0.12), (16.0, 0.94)] {
                    ctx.fill(Path(ellipseIn: CGRect(x: sun.x-r, y: sun.y-r, width: r*2, height: r*2)), with: .color(Color(red: 1, green: 0.86, blue: 0.67).opacity(a)))
                }
                for band in 0..<4 {
                    let baseline = h * (0.52 + Double(band) * 0.115)
                    var p = Path(); p.move(to: CGPoint(x: 0, y: h))
                    for step in 0...100 {
                        let x = Double(step) / 100
                        let t = Double(band) * 1.6 + Double(scene)
                        let frequency = [9.0, 5.0, 6.5][scene]
                        let ripple = scene == 0 ? abs(sin(x * 13 + t)) * 0.09 : cos(x * 7 + t) * 0.035
                        let y = baseline + h * (sin(x * frequency + t) * 0.10 + ripple)
                        p.addLine(to: CGPoint(x: x*w, y: y))
                    }
                    p.addLine(to: CGPoint(x: w, y: h)); p.closeSubpath()
                    ctx.fill(p, with: .color(skies[scene][0].opacity(0.34 + Double(band)*0.17)))
                }
            }
        }
    }
}

private struct HomeWeatherRow: View {
    @ObservedObject var model: HomeOutdoors
    @State private var details = false
    var body: some View {
        Button { details = true } label: {
            HStack(spacing: 6) {
                Image(systemName: model.weather.isLoaded ? model.weather.symbol : "cloud.sun").foregroundStyle(Color.ylctSun)
                Text(model.weather.isLoaded ? model.weather.city + " " + model.weather.temp + "°" : "出行天气")
                    .font(.subheadline.weight(.medium)).foregroundStyle(Color.white).lineLimit(1)
                if model.failed && model.weather.isLoaded { Text("上次").font(.caption2) }
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.white.opacity(0.85))
            }.padding(.horizontal, 12).frame(minHeight: 32)
                .ylctGlass(Capsule(), tint: .ylctInk.opacity(0.90), solid: .ylctInk, touch: true)
                .frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(PressStyle()).accessibilityLabel("出行天气")
            .accessibilityValue(model.weather.isLoaded ? model.weather.city + model.weather.text + model.weather.temp + "度" : "查看天气")
            .accessibilityIdentifier("home.weather")
            .sheet(isPresented: $details) { WeatherDetails(model: model, location: model.location) }
    }
}

private struct WeatherDetails: View {
    @ObservedObject var model: HomeOutdoors
    @ObservedObject var location: LocationProvider
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    var body: some View {
        NavigationStack {
            List {
                if model.weather.isLoaded {
                    Section(model.weather.citySource ?? "参考城市") {
                        Label(model.weather.city + " · " + model.weather.text + " " + model.weather.temp + "°", systemImage: model.weather.symbol)
                        if let time = model.weather.reportTime, !time.isEmpty { Text("天气发布：" + time).font(.footnote).foregroundStyle(.secondary) }
                    }.listRowBackground(YLCTReadingPlate())
                    if !model.weather.days.isEmpty {
                        Section("三天预报") {
                            ForEach(model.weather.days) { d in HStack { Text(d.name); Spacer(); Text(d.weather); Text(d.range).monospacedDigit() } }
                        }.listRowBackground(YLCTReadingPlate())
                    }
                }
                Section {
                    if model.failed { Text(model.weather.isLoaded ? "更新失败，显示上次获取的数据。" : "天气暂时无法获取，可以稍后重试。").foregroundStyle(.secondary) }
                    Button(model.loading ? "正在更新…" : "刷新天气") { Task { await model.refresh(force: true) } }.disabled(model.loading)
                    if location.status == "未授权" {
                        Button("在设置中允许定位") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                    } else {
                        Button("使用当前位置", systemImage: "location") { location.request() }
                        if ["定位中", "已授权", "定位失败"].contains(location.status) { Text(location.status).font(.caption) }
                    }
                } footer: { Text("默认按网络估算城市，可能与所在地不同。点「使用当前位置」才会用大致坐标查询天气。") }.listRowBackground(YLCTReadingPlate())
            }.ylctListCanvas().navigationTitle("出行天气").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
