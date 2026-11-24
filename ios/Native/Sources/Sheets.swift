import SwiftUI
import PhotosUI
import UIKit

struct FieldBox<Content: View>: View {
    let label: String
    let content: Content
    init(label: String, @ViewBuilder content: () -> Content) { self.label = label; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: label)
            content.font(.body).foregroundStyle(Color.ylctText)
                .padding(14).background(Color.ylctField, in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.ylctStroke, lineWidth: 0.7) }
                .accessibilityLabel(label)
        }
    }
}
struct ScreenshotButton: View {
    let title: String
    let busy: Bool
    @Binding var item: PhotosPickerItem?
    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            HStack(spacing: 12) {
                if busy { ProgressView().tint(.ylctBlue) }
                else { Image(systemName: "text.viewfinder").font(.title2) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(busy ? "正在识别，请稍候…" : title).font(.headline)
                    Text("选择截图后自动填写，再由你核对").font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }
                Spacer()
                Image(systemName: "plus.circle").font(.title3)
            }.foregroundStyle(Color.ylctBlue).padding(16).frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.ylctBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(PressStyle()).disabled(busy)
    }
}
private func screenshotData(_ item: PhotosPickerItem) async throws -> Data {
    guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { throw BackendError.decode }
    let scale = min(1, 2048 / max(image.size.width, image.size.height))
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let resized = UIGraphicsImageRenderer(size: CGSize(width: image.size.width * scale, height: image.size.height * scale), format: format).image { _ in
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width * scale, height: image.size.height * scale))
    }
    guard let compressed = resized.jpegData(compressionQuality: 0.86) else { throw BackendError.decode }
    return compressed
}

struct AddressSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pickerItem: PhotosPickerItem?
    @State private var ocrMessage: String?
    @State private var busy = false
    @State private var confirmClear = false
    @State private var showNavigation = false
    @State private var showCallConfirmation = false
    @State private var phoneToConfirm: CustomerPhone?
    private enum AddressField: Hashable { case address, building, room, floor, phone, note }
    @FocusState private var focusedField: AddressField?
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("这一单，送到哪里？").font(.title2.bold()).foregroundStyle(Color.ylctText)
                        Text("地址用于导航和送达提醒，完整电话可直接联系顾客。")
                            .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    }
                    ScreenshotButton(title: "识别订单截图", busy: busy, item: $pickerItem)
                    if let ocrMessage { Text(ocrMessage).font(.subheadline).foregroundStyle(Color.ylctTextSecondary).accessibilityAddTraits(.updatesFrequently) }
                    VStack(spacing: 17) {
                        FieldBox(label: "小区 / 详细地址") { TextField("填写城市、小区、街道或门牌", text: $app.address.community, axis: .vertical).lineLimit(1...3).focused($focusedField, equals: .address).accessibilityIdentifier("delivery.address") }
                        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 17)) : AnyLayout(HStackLayout(spacing: 12))
                        layout {
                            FieldBox(label: "楼栋") { TextField("如 A 栋", text: $app.address.building).focused($focusedField, equals: .building).accessibilityIdentifier("delivery.building") }
                            FieldBox(label: "房号") { TextField("如 1502", text: $app.address.room).keyboardType(.numbersAndPunctuation).focused($focusedField, equals: .room).accessibilityIdentifier("delivery.room") }
                            FieldBox(label: "楼层") { TextField("如 15", text: $app.address.floor).keyboardType(.numberPad).focused($focusedField, equals: .floor).accessibilityIdentifier("delivery.floor") }
                        }
                        FieldBox(label: "顾客电话（选填）") { TextField("完整手机号或含区号座机", text: $app.address.phone).keyboardType(.phonePad).focused($focusedField, equals: .phone).accessibilityIdentifier("delivery.phone") }
                        if !app.address.phone.isEmpty, app.address.customerPhone == nil {
                            Text("号码暂不可拨打：请填写完整手机号或含区号座机，尾号和隐藏号码不能拨号。")
                                .font(.caption).foregroundStyle(Color.ylctOrange).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        FieldBox(label: "送达备注（选填）") { TextField("如：放门口，请勿敲门", text: $app.address.note, axis: .vertical).lineLimit(1...3).focused($focusedField, equals: .note).accessibilityIdentifier("delivery.note") }
                    }.ylctCard(padding: 16)
                    Text("先电话联系，到现场再切面对面。进入沟通不会自动拨号或发声。")
                        .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }.padding(20)
            }
            .accessibilityIdentifier("delivery.form")
            .scrollDismissesKeyboard(.interactively).background(YLCTBackground())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if focusedField == nil {
                        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 12))
                        layout {
                            OrderActionButton(title: "导航", icon: "location.fill") { showNavigation = true }
                                .disabled(busy || app.address.navigationQuery.isEmpty).accessibilityIdentifier("delivery.navigate")
                            OrderActionButton(title: "联系顾客", icon: "phone.fill") {
                                phoneToConfirm = app.address.customerPhone
                                showCallConfirmation = phoneToConfirm != nil
                            }.disabled(busy || app.address.customerPhone == nil).accessibilityIdentifier("delivery.call")
                        }
                        if app.address.navigationQuery.isEmpty || app.address.customerPhone == nil {
                            Text(app.address.navigationQuery.isEmpty ? "填小区 / 街道后可导航；填完整号码后可拨号。" : "填完整号码后可联系顾客，也可以直接进入沟通。")
                                .font(.caption).foregroundStyle(Color.ylctTextSecondary).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        PrimaryButton(title: "进入电话沟通", systemImage: "text.bubble.fill") {
                            focusedField = nil
                            app.mode = .deliver
                            app.continueToDialogue()
                        }.disabled(busy).accessibilityIdentifier("delivery.continue")
                        Text("只进入页面，不会自动拨号或发声").font(.caption2).foregroundStyle(Color.ylctTextSecondary)
                    }
                }.padding(focusedField == nil ? 16 : 0).ylctDock()
            }
            .navigationTitle("送餐").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNavigation) { OrderNavigationSheet(address: app.address).environmentObject(app) }
            .alert("核对顾客号码", isPresented: $showCallConfirmation, presenting: phoneToConfirm) { phone in
                Button("进入沟通并拨号") {
                    focusedField = nil
                    app.mode = .deliver
                    app.continueToDialogue(call: phone)
                }
                Button("复制号码") { UIPasteboard.general.string = phone.number }
                Button("取消", role: .cancel) {}
            } message: { phone in
                Text("\(phone.number)\n确认后打开系统拨号，回到 App 即可使用电话播报。")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("清空") { confirmClear = true }.disabled(busy) }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { focusedField = nil } }
            }
            .confirmationDialog("清空这一单的地址信息？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) { app.address = AddressDraft(); ocrMessage = nil }
            }
        }.tint(.ylctBlue)
            .task(id: pickerItem) {
                guard let pickerItem else { return }
                busy = true
                defer { busy = false }
                do {
                    let data = try await screenshotData(pickerItem)
                    try Task.checkCancellation()
                    ocrMessage = await app.recognizeScreenshot(data, pickup: false)
                } catch is CancellationError { return }
                catch { ocrMessage = "图片读取失败，请重新选择。" }
            }
    }
}

struct PickupSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var ocrMessage: String?
    @State private var busy = false
    @State private var confirmClear = false
    @FocusState private var editing: Bool
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("取餐信息，先准备好").font(.title2.bold()).foregroundStyle(Color.ylctText)
                        Text("让商家看清取餐码，也能帮你直接说出来。")
                            .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    }
                    ScreenshotButton(title: "识别取餐截图", busy: busy, item: $pickerItem)
                    if let ocrMessage { Text(ocrMessage).font(.subheadline).foregroundStyle(Color.ylctTextSecondary).accessibilityAddTraits(.updatesFrequently) }
                    VStack(spacing: 17) {
                        FieldBox(label: "商家名称") { TextField("填写店名", text: $app.pickup.merchant).focused($editing) }
                        FieldBox(label: "取餐码") { TextField("如 A123", text: $app.pickup.code).textInputAutocapitalization(.characters).autocorrectionDisabled().focused($editing) }
                        FieldBox(label: "手机号 / 手机尾号（选填）") { TextField("填写手机号或尾号", text: $app.pickup.phone).keyboardType(.phonePad).focused($editing) }
                        FieldBox(label: "取餐地址（选填）") { TextField("填写商家地址", text: $app.pickup.address, axis: .vertical).lineLimit(1...3).focused($editing) }
                    }.ylctCard(padding: 16)
                    Label("取餐码与手机尾号分开保存，不会覆盖顾客的手机号。", systemImage: "checkmark.shield")
                        .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }.padding(20)
            }.scrollDismissesKeyboard(.interactively).background(YLCTBackground())
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(title: "带上信息，开始沟通", systemImage: "bubble.left.and.bubble.right.fill") {
                        editing = false
                        app.mode = .pickup
                        app.continueToDialogue()
                    }.disabled(busy).padding(16).ylctDock()
                }
                .navigationTitle("取餐").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss() } }
                    ToolbarItem(placement: .topBarTrailing) { Button("清空") { confirmClear = true }.disabled(busy) }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { editing = false } }
                }
                .confirmationDialog("清空这一单的取餐信息？", isPresented: $confirmClear, titleVisibility: .visible) {
                    Button("清空", role: .destructive) { app.pickup = PickupDraft(); ocrMessage = nil }
                }
        }.tint(.ylctBlue)
            .task(id: pickerItem) {
                guard let pickerItem else { return }
                busy = true
                defer { busy = false }
                do {
                    let data = try await screenshotData(pickerItem)
                    try Task.checkCancellation()
                    ocrMessage = await app.recognizeScreenshot(data, pickup: true)
                } catch is CancellationError { return }
                catch { ocrMessage = "图片读取失败，请重新选择。" }
            }
    }
}

struct OrderActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(enabled ? Color.ylctBlue : Color.ylctTextSecondary)
                .background(Color.ylctSurface, in: RoundedRectangle(cornerRadius: 15))
                .overlay { RoundedRectangle(cornerRadius: 15).stroke(Color.ylctStroke, lineWidth: 1) }
        }.buttonStyle(PressStyle()).opacity(enabled ? 1 : 0.55)
    }
}

struct OrderNavigationSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    @State private var travelMode: NavigationTravelMode = .cycling
    @FocusState private var editing: Bool
    let address: AddressDraft
    private var navigationURL: URL? {
        if #available(iOS 18.4, *) { return OrderNavigationLink.url(for: query, mode: travelMode) }
        return OrderNavigationLink.url(for: query, mode: travelMode, unified: false)
    }
    init(address: AddressDraft) {
        self.address = address
        _query = State(initialValue: address.navigationQuery)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Label("先核对，再出发", systemImage: "location.circle.fill").font(.title2.bold()).foregroundStyle(Color.ylctText)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("这一单送到").font(.caption.weight(.semibold)).foregroundStyle(Color.ylctBlue)
                        Text(address.summary).font(.headline).foregroundStyle(Color.ylctText).textSelection(.enabled)
                        if !address.note.isEmpty {
                            Label(address.note, systemImage: "note.text").font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).ylctCard()
                    FieldBox(label: "地图搜索地址") {
                        TextField("补充城市、街道和小区名称", text: $query, axis: .vertical)
                            .lineLimit(2...4).focused($editing).accessibilityIdentifier("delivery.map-query")
                    }
                    Picker("出行方式", selection: $travelMode) {
                        ForEach(NavigationTravelMode.allCases) { mode in Text(mode.label).tag(mode) }
                    }.pickerStyle(.menu).font(.headline).accessibilityIdentifier("delivery.travel-mode")
                    Text("地图使用小区 / 街道定位。楼栋、房号、楼层和备注保留在订单里，送达时继续提醒。可在这里补充城市，避免找到同名地点。")
                        .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    Text("在系统地图中核对目的地，再选择适合你的路线方式。这里不会直接开始导航，也不会修改订单地址。")
                        .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    Button { UIPasteboard.general.string = query.trimmingCharacters(in: .whitespacesAndNewlines) } label: {
                        Label("复制导航地址", systemImage: "doc.on.doc").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }.disabled(OrderNavigationLink.url(for: query) == nil)
                }.padding(20)
            }.background(YLCTBackground()).scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(title: "在地图中确认路线", systemImage: "arrow.up.right.square") {
                        guard let url = navigationURL else { return }
                        editing = false
                        app.openExternal(url, failure: "未能打开系统地图。可以复制地址，粘贴到你常用的地图 App。")
                    }.disabled(OrderNavigationLink.url(for: query) == nil).padding(16).ylctDock()
                        .accessibilityIdentifier("delivery.open-map")
                }
                .navigationTitle("导航目的地").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("返回订单") { dismiss() } }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { editing = false } }
                }
                .alert("地图提示", isPresented: Binding(get: { app.externalActionMessage != nil }, set: { if !$0 { app.externalActionMessage = nil } })) {
                    Button("知道了", role: .cancel) { app.externalActionMessage = nil }
                } message: { Text(app.externalActionMessage ?? "") }
        }.tint(.ylctBlue)
    }
}
