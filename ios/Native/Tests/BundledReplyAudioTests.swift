import Foundation

@main
struct BundledReplyAudioTests {
    @MainActor static func main() throws {
        var checks = 0
        func check(_ result: Bool, _ label: String) { precondition(result, label); checks += 1; print("PASS: \(label)") }
        let directory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Sources/Resources/Presets")
        let expected = Set(PhraseShortcut.allTexts + ["我是听障骑手，请用文字和我沟通，谢谢。"])
        check(Set(BundledReplyAudio.files.keys) == expected, "Every fixed app reply is declared in the bundled catalog")
        check(Set(BundledReplyAudio.files.values).count == expected.count, "Different replies cannot accidentally share an audio filename")
        check(BundledReplyAudio.resourceName(text: "用户临时输入的内容", voice: .female) == nil, "Arbitrary typed text is not mistaken for bundled audio")
        for text in expected.sorted() {
            var voices: [PhraseVoice: Data] = [:]
            for voice in PhraseVoice.allCases {
                let name = BundledReplyAudio.resourceName(text: text, voice: voice)!
                let url = directory.appendingPathComponent(name + ".wav")
                check(FileManager.default.fileExists(atPath: url.path), "Bundled file exists: \(name)")
                let data = try Data(contentsOf: url)
                try CustomPhraseStore.validateAudio(data)
                voices[voice] = data
                check(data.count > 44, "Bundled file decodes with nonzero duration: \(name)")
            }
            check(voices[.female] != voices[.male], "Male and female recordings are distinct: \(text)")
        }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("ylct-offline-builtins-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temporary) }
        var networkCalls = 0
        let library = CustomPhraseLibrary(root: temporary) { _, _ in
            networkCalls += 1
            throw URLError(.notConnectedToInternet)
        }
        let shortcuts = library.shortcuts(including: PhraseShortcut.phoneTexts + PhraseShortcut.faceTexts)
        check(shortcuts.count == 9 && shortcuts.allSatisfy { $0.custom == nil }, "Fresh offline library exposes all built-in shortcuts immediately")
        check(networkCalls == 0 && library.phrases.isEmpty, "Browsing built-ins neither synthesizes nor inserts user phrases")
        check(!FileManager.default.fileExists(atPath: temporary.path), "Built-in replies require no generated library or cache")
        print("Final total: \(checks) bundled-audio checks passed.")
    }
}
