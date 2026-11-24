import SwiftUI

public struct PhrasesView: View {
    public let scene: SceneKind
    public let store: any YZPhraseStoring
    public let onBack: () -> Void
    public let onSend: (String) -> Void

    @State private var selectedSub: String
    @State private var customPhrases: [String] = []
    @State private var sheetMode: SheetMode?
    @State private var errorMessage: String?

    @Environment(\.colorScheme) private var scheme

    public init(
        scene: SceneKind,
        initialSub: String? = nil,
        store: any YZPhraseStoring,
        onBack: @escaping () -> Void,
        onSend: @escaping (String) -> Void
    ) {
        self.scene = scene
        self.store = store
        self.onBack = onBack
        self.onSend = onSend

        let subs = SceneCatalog.subs(for: scene)
        let fallback = SceneCatalog.defaultSub(for: scene)
        let initial = initialSub.flatMap { subs.contains($0) ? $0 : nil } ?? fallback
        self._selectedSub = State(initialValue: initial)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                backButton

                Text("我的常用语")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(SceneTheme.ink(scheme))
                    .padding(.top, 12)

                Text("句子只保存在这台设备，点一下就会发到对话里。")
                    .font(.system(size: 13))
                    .foregroundStyle(SceneTheme.ink2(scheme))
                    .padding(.top, 6)

                SceneUnderlineTabs(items: subs, selected: selectedSub, onSelect: { selectedSub = $0 })
                    .padding(.top, 12)

                addBar
                card
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(SceneTheme.bg(scheme).ignoresSafeArea())
        .task(id: selectedSub) {
            reload()
        }
        .sheet(item: $sheetMode) { mode in
            editorSheet(mode)
        }
        .alert("操作失败", isPresented: errorBinding) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var subs: [String] {
        SceneCatalog.subs(for: scene)
    }

    private var builtInPhrases: [String] {
        SceneCatalog.phrases(for: scene, sub: selectedSub)
    }

    private var backButton: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(SceneTheme.primary(scheme))
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(SceneTheme.card(scheme))
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(scheme == .dark ? 0 : 0.06),
                    radius: 4,
                    x: 0,
                    y: 2
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回我的")

            Spacer()
        }
    }

    private var addBar: some View {
        HStack {
            Text("共 \(builtInPhrases.count + customPhrases.count) 条")
                .font(.system(size: 12))
                .foregroundStyle(SceneTheme.ink3(scheme))

            Spacer()

            Button {
                sheetMode = .add
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("添加一句")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(SceneTheme.primary(scheme))
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(SceneTheme.soft(scheme))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
    }

    private var card: some View {
        VStack(spacing: 0) {
            if !builtInPhrases.isEmpty {
                sectionHead("内置句子")
                ForEach(builtInPhrases, id: \.self) { text in
                    manageRow(text, isCustom: false)
                }
            }

            sectionHead("我加的句子")

            if customPhrases.isEmpty {
                Text("还没有自己加的句子。")
                    .font(.system(size: 13))
                    .foregroundStyle(SceneTheme.ink3(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
            } else {
                ForEach(customPhrases, id: \.self) { text in
                    manageRow(text, isCustom: true)
                }
            }
        }
        .background(SceneTheme.card(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.top, 12)
    }

    private func sectionHead(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.44)
            .foregroundStyle(SceneTheme.ink3(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .background(SceneTheme.bg(scheme))
    }

    private func manageRow(_ text: String, isCustom: Bool) -> some View {
        HStack(spacing: 10) {
            Button {
                onSend(text)
            } label: {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(SceneTheme.ink(scheme))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isCustom {
                Menu {
                    Button("编辑") {
                        sheetMode = .edit(text)
                    }
                    Button("删除", role: .destructive) {
                        deletePhrase(text)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SceneTheme.ink3(scheme))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("编辑或删除这句")
            }

            Text(isCustom ? "我加的" : "内置")
                .font(.system(size: 11))
                .foregroundStyle(SceneTheme.ink3(scheme))
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SceneTheme.line(scheme))
                .frame(height: 1)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { newValue in
                if !newValue { errorMessage = nil }
            }
        )
    }

    private func editorSheet(_ mode: SheetMode) -> some View {
        PhraseEditorSheet(
            title: mode.isEdit ? "编辑句子" : "添加一句",
            initialText: mode.initialText,
            maxLength: YZPhraseLimit.maxLength
        ) { text in
            try commit(text, mode: mode)
            reload()
        }
    }

    private func commit(_ text: String, mode: SheetMode) throws {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if builtInPhrases.contains(value) {
            throw YZPhraseError.duplicate
        }

        switch mode {
        case .add:
            try store.addPhrase(value, scene: scene, sub: selectedSub)
        case .edit(let original):
            try store.updatePhrase(original, to: value, scene: scene, sub: selectedSub)
        }
    }

    private func reload() {
        do {
            customPhrases = try store.customPhrases(scene: scene, sub: selectedSub)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deletePhrase(_ text: String) {
        do {
            try store.deletePhrase(text, scene: scene, sub: selectedSub)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private enum SheetMode: Identifiable {
        case add
        case edit(String)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let text):
                return "edit-\(text)"
            }
        }

        var isEdit: Bool {
            if case .edit = self { return true }
            return false
        }

        var initialText: String {
            switch self {
            case .add:
                return ""
            case .edit(let text):
                return text
            }
        }
    }
}

struct PhraseEditorSheet: View {
    let title: String
    let maxLength: Int
    let onSave: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var errorMessage: String?

    init(title: String, initialText: String, maxLength: Int, onSave: @escaping (String) throws -> Void) {
        self.title = title
        self.maxLength = maxLength
        self.onSave = onSave
        self._text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField("输入一句话", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .font(.system(size: 16))

                HStack {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    Text("\(text.count)/\(maxLength)")
                        .font(.footnote)
                        .foregroundStyle(text.count > maxLength ? Color.red : Color.secondary)
                }
            }
            .padding(16)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(240)])
    }

    private func save() {
        do {
            try onSave(text)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}