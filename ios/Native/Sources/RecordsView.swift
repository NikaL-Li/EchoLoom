import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var app: AppState
    @State private var confirmAdd = false
    @State private var confirmUndo = false
    private var maximum: Int { max(app.records.map(\.count).max() ?? 0, 1) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("每一单，都算数").font(.system(.title, design: .rounded, weight: .bold)).foregroundStyle(Color.ylctText)
                    Text("记下自己的节奏，也记得好好休息。")
                        .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                }
                stats
                if let error = app.recordError {
                    Label(error, systemImage: "exclamationmark.triangle").font(.subheadline).foregroundStyle(Color.ylctDanger).ylctCard()
                }
                PrimaryButton(title: "记一单已完成的送餐", systemImage: "plus") { confirmAdd = true }
                    .disabled(app.recordError != nil)
                if app.completedOrders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bicycle.circle").font(.system(size: 48, weight: .light)).foregroundStyle(Color.ylctBlue)
                        Text("从第一单开始").font(.headline).foregroundStyle(Color.ylctText)
                        Text("完成送餐后记一笔，真实记录会留在这台手机上。")
                            .font(.subheadline).foregroundStyle(Color.ylctTextSecondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 24).ylctCard()
                } else { history }
                HStack {
                    Label("本机记录 · 暂不云端同步", systemImage: "iphone")
                    Spacer()
                    if !app.completedOrders.isEmpty {
                        Button("撤销上一单") { confirmUndo = true }.foregroundStyle(Color.ylctBlue).frame(minHeight: 44)
                    }
                }.font(.caption).foregroundStyle(Color.ylctTextSecondary)
            }.padding(20)
        }
        .onAppear { app.refreshRecordSummary() }
        .confirmationDialog("确认这单已经送达？", isPresented: $confirmAdd, titleVisibility: .visible) {
            Button("确认完成，记一单") { app.completeOrder() }
            Button("取消", role: .cancel) {}
        } message: { Text("只记录完成数量，不保存顾客地址和手机号。") }
        .confirmationDialog("撤销最近添加的一条记录？", isPresented: $confirmUndo, titleVisibility: .visible) {
            Button("撤销上一单", role: .destructive) { app.undoLastOrder() }
            Button("保留", role: .cancel) {}
        }
    }
    private var stats: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("今天完成").font(.subheadline.weight(.medium)).foregroundStyle(Color.ylctTextSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(app.todayCount)").font(.system(size: 64, weight: .bold, design: .rounded)).monospacedDigit()
                        Text("单").font(.headline).foregroundStyle(Color.ylctTextSecondary)
                    }.foregroundStyle(Color.ylctText)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").font(.system(size: 38)).foregroundStyle(Color.ylctMint)
                    .padding(18).background(Color.ylctMint.opacity(0.09), in: Circle())
            }
            HStack(spacing: 10) {
                stat("近 7 天", app.weekCount)
                stat("本月", app.monthCount)
                stat("今年", app.yearCount)
            }
        }.ylctCard(padding: 20)
    }
    private func stat(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 7) {
            Text(title).font(.caption).foregroundStyle(Color.ylctTextSecondary)
            Text("\(value)").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Color.ylctText)
        }.frame(maxWidth: .infinity).padding(.vertical, 14).background(Color.ylctSurfaceSoft, in: RoundedRectangle(cornerRadius: 16))
    }
    private var history: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("近 30 天").font(.headline).foregroundStyle(Color.ylctText)
                Spacer()
                Text("\(app.records.reduce(0) { $0 + $1.count }) 单").font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
            }
            ForEach(app.records) { record in
                HStack(spacing: 12) {
                    Text(record.label).font(.subheadline).frame(minWidth: 72, alignment: .leading)
                    GeometryReader { proxy in
                        Capsule().fill(Color.ylctSurfaceSoft)
                            .overlay(alignment: .leading) {
                                Capsule().fill(record.label == "今天" ? Color.ylctMint : Color.ylctBlue)
                                    .frame(width: proxy.size.width * CGFloat(record.count) / CGFloat(maximum))
                            }
                    }.frame(height: 7).accessibilityHidden(true)
                    Text("\(record.count)").font(.subheadline.weight(.semibold)).monospacedDigit().frame(minWidth: 25, alignment: .trailing)
                }.foregroundStyle(Color.ylctText).frame(minHeight: 30)
                    .accessibilityElement(children: .ignore).accessibilityLabel("\(record.label)，完成 \(record.count) 单")
            }
        }.ylctCard(padding: 18)
    }
}
