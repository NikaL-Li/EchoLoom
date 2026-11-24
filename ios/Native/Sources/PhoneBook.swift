import SwiftUI
import ContactsUI

// The system grants a one-time selection, not a whole-book authorization.
private struct ChosenPerson {
    let name: String
    let numbers: [(label: String, value: String)]
}
// CNContactPicker dismisses its own native controller. Present it directly
// from this anchor so selecting a contact never dismisses the SwiftUI dialer.
private struct ContactPickerAnchor: UIViewControllerRepresentable {
    @Binding var open: Bool
    let finish: (ChosenPerson?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ anchor: UIViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.done = { person in open = false; finish(person) }
        guard open, !coordinator.showing else { return }
        coordinator.showing = true
        DispatchQueue.main.async {
            guard anchor.viewIfLoaded?.window != nil else { coordinator.complete(nil); return }
            let picker = CNContactPickerViewController()
            picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
            picker.predicateForSelectionOfContact = NSPredicate(value: true)
            picker.delegate = coordinator
            anchor.present(picker, animated: true)
            picker.presentationController?.delegate = coordinator
        }
    }
    final class Coordinator: NSObject, CNContactPickerDelegate, UIAdaptivePresentationControllerDelegate {
        var showing = false
        var done: ((ChosenPerson?) -> Void)?
        func complete(_ selected: ChosenPerson?) {
            guard showing else { return }
            done?(selected); showing = false
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { complete(nil) }
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) { complete(nil) }
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let numbers = contact.phoneNumbers.map {
                (CNLabeledValue<NSString>.localizedString(forLabel: $0.label ?? CNLabelOther), $0.value.stringValue)
            }
            complete(ChosenPerson(name: CNContactFormatter.string(from: contact, style: .fullName) ?? "", numbers: numbers))
        }
    }
}
struct ContactNumberButton: View {
    let picked: (String, String) -> Void
    @State private var open = false
    @State private var person: ChosenPerson?
    var body: some View {
        Button("从通讯录选择号码", systemImage: "person.crop.circle") { person = nil; open = true }
            .background { ContactPickerAnchor(open: $open) { selection in
                guard let selection else { return }
                if selection.numbers.count == 1, let n = selection.numbers.first { picked(selection.name, n.value) }
                else { person = selection }
            }.frame(width: 1, height: 1) }
        if let person {
            Text("选择" + person.name + "的号码").font(.caption).foregroundStyle(.secondary)
            ForEach(person.numbers.indices, id: \.self) { i in
                let n = person.numbers[i]
                Button(n.label + " · " + n.value) { picked(person.name,n.value); self.person = nil }
            }
            Button("取消选择", role: .cancel) { self.person = nil }
        }
    }
}

struct OpeningPhrasePicker: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let selected: String?
    let allowDefault: Bool
    let choose: (String?) -> Bool
    @State private var create = false
    @State private var savedNotice = false
    var body: some View {
        List {
            UniversalStoreNotice()
            if savedNotice { Label("添加成功，已选为开场白", systemImage: "checkmark.circle.fill").foregroundStyle(Color.ylctMint) }
            if allowDefault { Button { if choose(nil) { dismiss() } } label: { row("跟随通用开场白", id: nil) } }
            Section {
                Button("写一句新开场白", systemImage: "plus") { app.customPhrases.prepareEditor(); create = true }
            } footer: { Text("新开场白会保存男、女两种声音，也会出现在常用语中。") }.listRowBackground(YLCTReadingPlate())
            Section("已在本机的语音") {
                ForEach(app.customPhrases.shortcuts(including: PhraseShortcut.faceTexts)) { phrase in
                    Button { if choose(phrase.id) { dismiss() } } label: { row(phrase.text, id: phrase.id) }
                        .disabled(phrase.custom.map { !app.customPhrases.ready($0) } ?? false)
                }
            }.listRowBackground(YLCTReadingPlate())
        }.ylctListCanvas().navigationTitle("选择开场白")
            .sheet(isPresented: $create) {
                CustomPhraseEditor(phrase: nil, completedText: { text in
                    if let saved = app.customPhrases.phrase(matching: text) {
                        savedNotice = choose(PhraseShortcut.saved(saved).id)
                    }
                }) {}
            }
    }
    private func row(_ label: String, id: String?) -> some View {
        HStack { Text(label); Spacer(); if selected == id { Image(systemName: "checkmark") } }
    }
}
struct OpeningSettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var editing: OpeningContact?
    private var settings: OpeningSettings { app.universal.openings }
    var body: some View {
        Form {
            Section {
                Toggle("接通后自动播报", isOn: Binding(get: { settings.automatic }, set: { enabled in
                    if app.universal.updateOpenings({ $0.automatic = enabled }), !enabled { app.opening.cancel("") }
                })).accessibilityIdentifier("opening.auto")
                Stepper("接通后等 \(settings.delay) 秒", value: Binding(get: { settings.delay }, set: { delay in
                    app.universal.updateOpenings { $0.delay = delay }
                }), in: 1...8)
                NavigationLink {
                    OpeningPhrasePicker(selected: settings.phraseID, allowDefault: false) { id in
                        guard let id else { return false }; return app.universal.updateOpenings { $0.phraseID = id }
                    }
                } label: { VStack(alignment: .leading) { Text("通用开场白"); Text(app.openingText(for: "") ?? "语音已移除，请重新选择").font(.caption).foregroundStyle(.secondary) } }
            } footer: { Text("仅用于在「电话辅助」中确认拨出的电话。需要通话注入可用；若系统暂停应用、通话被保留或有第二路电话，会跳过自动播报。") }.listRowBackground(YLCTReadingPlate())
            Section {
                ForEach(settings.contacts) { c in
                    Button { editing = c } label: {
                        VStack(alignment: .leading) { Text(c.name); Text(c.number).font(.caption).foregroundStyle(.secondary) }
                    }.swipeActions { Button("移除", role: .destructive) { app.universal.updateOpenings { $0.contacts.removeAll { $0.id == c.id } } } }
                }
                Button("添加常用联系人", systemImage: "person.badge.plus") { editing = OpeningContact(name: "", number: "") }
            } header: { Text("常用联系人") } footer: { Text("只在这台手机上保存你选的姓名、号码和开场白。") }.listRowBackground(YLCTReadingPlate())
            UniversalStoreNotice()
        }.ylctListCanvas().navigationTitle("通话开场").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { OpeningContactEditor(contact: $0) }
    }
}

struct OpeningContactEditor: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State var contact: OpeningContact
    private var duplicate: Bool {
        guard let found = app.universal.openings.contact(contact.number) else { return false }
        return found.id != contact.id
    }
    var body: some View {
        NavigationStack {
            Form {
                ContactNumberButton { contact.name = $0; contact.number = $1 }
                TextField("称呼", text: $contact.name)
                TextField("完整电话号码", text: $contact.number).keyboardType(.phonePad)
                if duplicate { Text("这个号码已在常用联系人里，请编辑已有联系人。").font(.footnote) }
                else if !contact.number.isEmpty && CustomerPhone(universal: contact.number) == nil { Text("请核对完整号码，境外号码须含国家区号。").font(.footnote) }
                NavigationLink {
                    OpeningPhrasePicker(selected: contact.phraseID, allowDefault: true) { contact.phraseID = $0; return true }
                } label: {
                    VStack(alignment: .leading) {
                        Text("专属开场白")
                        Text(contact.phraseID.map { id in app.customPhrases.shortcuts(including: PhraseShortcut.faceTexts).first { $0.id == id }?.text ?? "语音已移除，请重新选择" } ?? "跟随通用开场白").font(.caption).foregroundStyle(.secondary)
                    }
                }
                UniversalStoreNotice()
            }.ylctListCanvas().navigationTitle("常用联系人").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            guard let phone = CustomerPhone(universal: contact.number), !duplicate else { return }
                            contact.name = contact.name.trimmed; contact.number = phone.number
                            if app.universal.updateOpenings({ s in s.contacts.removeAll { $0.id == contact.id }; s.contacts.append(contact) }) { dismiss() }
                        }.disabled(contact.name.trimmed.isEmpty || CustomerPhone(universal: contact.number) == nil || duplicate)
                    }
                }
        }
    }
}
