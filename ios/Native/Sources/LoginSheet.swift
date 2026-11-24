import SwiftUI

struct LoginSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var phone = ""
    @State private var password = ""
    @State private var error = ""
    @State private var busy = false
    @FocusState private var editing: Bool
    private var valid: Bool { phone.range(of: #"^1[3-9][0-9]{9}$"#, options: .regularExpression) != nil && !password.isEmpty }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "person.crop.circle").font(.system(size: 52, weight: .light)).foregroundStyle(Color.ylctBlue)
                        Text("欢迎回来").font(.largeTitle.bold()).foregroundStyle(Color.ylctText)
                        Text("使用已有账号登录。送餐记录目前保存在本机，暂不随账号同步。")
                            .font(.subheadline).foregroundStyle(Color.ylctTextSecondary)
                    }
                    VStack(spacing: 18) {
                        FieldBox(label: "手机号") {
                            TextField("输入 11 位手机号", text: $phone).keyboardType(.phonePad).textContentType(.username).focused($editing)
                                .onChange(of: phone) { _, value in phone = String(value.filter { $0.isASCII && $0.isNumber }.prefix(11)) }
                        }
                        FieldBox(label: "密码") {
                            SecureField("输入账号密码", text: $password).textContentType(.password).submitLabel(.go).focused($editing)
                                .onSubmit { if valid && !busy { Task { await submit() } } }
                        }
                    }.disabled(busy)
                    if !error.isEmpty { Label(error, systemImage: "exclamationmark.circle").font(.subheadline).foregroundStyle(Color.ylctDanger).accessibilityAddTraits(.updatesFrequently) }
                    PrimaryButton(title: busy ? "正在登录…" : "登录", systemImage: busy ? nil : "arrow.right") { Task { await submit() } }
                        .disabled(!valid || busy)
                    Text("账号由线上服务校验，不在本地保存密码。")
                        .font(.caption).foregroundStyle(Color.ylctTextSecondary)
                }.padding(24)
            }.scrollDismissesKeyboard(.interactively).background(YLCTBackground())
                .navigationTitle("登录账号").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("关闭") { dismiss() }.disabled(busy) }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { editing = false } }
                }
        }.tint(.ylctBlue).interactiveDismissDisabled(busy)
    }
    private func submit() async {
        guard valid, !busy else { return }
        editing = false
        busy = true
        error = ""
        defer { busy = false }
        do { try await app.login(phone: phone, password: password); dismiss() }
        catch let problem as URLError {
            error = problem.code == .timedOut ? "连接超时，请稍后再试。" : "网络连接失败，请检查网络后重试。"
        } catch { self.error = error.localizedDescription }
    }
}
