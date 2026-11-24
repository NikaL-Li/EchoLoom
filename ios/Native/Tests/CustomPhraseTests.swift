import Foundation

@main
struct CustomPhraseTests {
    @MainActor static func main() async throws {
        var count = 0
        func check(_ passed: Bool, _ label: String) { precondition(passed, label); count += 1; print("PASS: \(label)") }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ylct-phrase-tests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let female = try Data(contentsOf: URL(fileURLWithPath: "Sources/Resources/Presets/preset_gate_f.wav"))
        let male = try Data(contentsOf: URL(fileURLWithPath: "Sources/Resources/Presets/preset_gate_m.wav"))
        let store = CustomPhraseStore(root: root)
        check(try store.load().isEmpty, "New library is empty")
        check(female != male, "Female and male fixtures are distinct")
        let first = try store.save(text: "  请发短信给我。  ", female: female, male: male)
        check(first.text == "请发短信给我。", "Trim whitespace before saving")
        check(store.isReady(first), "Both voice files exist before item is usable")
        check(try Data(contentsOf: store.audioURL(for: first, voice: .female)) == female, "Female audio uses its own file")
        check(try Data(contentsOf: store.audioURL(for: first, voice: .male)) == male, "Male audio uses its own file")
        check(try CustomPhraseStore(root: root).load() == [first], "Relaunch reloads saved text and both file identities")
        do { _ = try store.save(text: first.text, female: female, male: male); check(false, "Reject duplicates") } catch { check(true, "Reject duplicate phrases") }
        do { _ = try store.save(text: "", female: female, male: male); check(false, "Reject empty") } catch { check(true, "Reject blank phrases") }
        do { _ = try store.save(text: String(repeating: "字", count: 201), female: female, male: male); check(false, "Reject long") } catch { check(true, "Reject more than 200 characters") }
        do { _ = try store.save(text: "修改失败", female: female, male: Data("broken".utf8), replacing: first.id); check(false, "Reject broken") } catch { check(true, "Reject incomplete or broken second voice") }
        check(try store.load() == [first] && store.isReady(first), "Failed edit preserves original phrase and files")
        let second = try store.save(text: "请在门口等一下。", female: female, male: male, replacing: first.id)
        check(second.id == first.id && second.audioID != first.audioID, "Edit keeps phrase identity but atomically replaces audio pair")
        check(!FileManager.default.fileExists(atPath: store.audioURL(for: first, voice: .female).path), "Successful edit removes superseded voice files")
        check(try store.load() == [second], "Edit has a single visible phrase")
        try FileManager.default.removeItem(at: store.audioURL(for: second, voice: .male))
        check(!store.isReady(second), "Missing male voice marks the whole pair unavailable")
        let repaired = try store.save(text: second.text, female: female, male: male, replacing: second.id)
        check(store.isReady(repaired), "Regeneration repairs the missing pair")
        try store.delete(first) // Old UI snapshot must remove both current audio files.
        do { _ = try store.save(text: first.text, female: female, male: male, replacing: first.id); check(false, "Stale edit must not resurrect deleted text") } catch CustomPhraseError.missing { check(true, "Stale edit rejected") }
        check(try store.load().isEmpty, "Delete removes phrase metadata")
        check(!FileManager.default.fileExists(atPath: store.audioURL(for: repaired, voice: .female).path) && !FileManager.default.fileExists(atPath: store.audioURL(for: repaired, voice: .male).path), "Delete removes both voice files")
        let corrupt = Data("invalid manifest, preserve me".utf8)
        try corrupt.write(to: root.appendingPathComponent("phrases.json"))
        do { _ = try store.save(text: "不能覆盖旧数据", female: female, male: male); check(false, "Do not overwrite") } catch { check(true, "Corrupt manifest blocks destructive replacement") }
        check(try Data(contentsOf: root.appendingPathComponent("phrases.json")) == corrupt, "Corrupt original manifest stays intact")

        let generationRoot = root.appendingPathComponent("generation")
        var calls: [PhraseVoice: Int] = [:]
        let library = CustomPhraseLibrary(root: generationRoot) { _, voice in
            calls[voice, default: 0] += 1
            if voice == .male && calls[voice] == 1 { throw URLError(.notConnectedToInternet) }
            return voice == .female ? female : male
        }
        var saved = false
        library.generate(text: "请稍等。") { saved = true }
        while library.isGenerating { try await Task.sleep(for: .milliseconds(10)) }
        check(!saved && library.phrases.isEmpty && library.femaleReady && !library.maleReady, "A single generated voice cannot appear as a saved phrase")
        library.generate(text: "请稍等。") { saved = true }
        while library.isGenerating { try await Task.sleep(for: .milliseconds(10)) }
        check(saved && library.phrases.count == 1, "Retry saves only after both voices succeed")
        check(calls[.female] == 1 && calls[.male] == 2, "Retry reuses the successful voice instead of paying twice")
        let cancelled = CustomPhraseLibrary(root: root.appendingPathComponent("cancelled")) { _, _ in
            try await Task.sleep(for: .seconds(1)); return female
        }
        cancelled.generate(text: "取消生成") { preconditionFailure("Cancelled operation must not save") }
        cancelled.cancelGeneration()
        try await Task.sleep(for: .milliseconds(30))
        check(cancelled.phrases.isEmpty && !cancelled.isGenerating, "Cancellation cannot commit a late response")
        check(cancelled.progress == "已取消，尚未保存", "Cancellation leaves a truthful visible status")
        let orderRoot = root.appendingPathComponent("ordering")
        let orderStore = CustomPhraseStore(root: orderRoot)
        let firstOrdered = try orderStore.save(text: "这是第一句", female: female, male: male)
        let secondOrdered = try orderStore.save(text: "这是第二句", female: female, male: male)
        var orderSyntheses = 0
        let orderedLibrary = CustomPhraseLibrary(root: orderRoot) { _, voice in
            orderSyntheses += 1; return voice == .female ? female : male
        }
        let originalIDs = orderedLibrary.sortableShortcuts.map(\.id)
        var reordered = originalIDs
        reordered.removeAll { $0 == PhraseShortcut.saved(secondOrdered).id }
        reordered.insert(PhraseShortcut.saved(secondOrdered).id, at: 0)
        check(orderedLibrary.reorder(reordered), "Drag-equivalent move can place second custom phrase first")
        check(orderedLibrary.phrases.map(\.id) == [secondOrdered.id, firstOrdered.id], "Custom manager reflects the saved order")
        let systemID = PhraseShortcut.builtIn(PhraseShortcut.phoneTexts[2]).id
        reordered.removeAll { $0 == systemID }; reordered.insert(systemID, at: 0)
        check(orderedLibrary.reorder(reordered), "A system phrase can move ahead of custom phrases")
        check(orderedLibrary.shortcuts(including: PhraseShortcut.phoneTexts).first?.id == systemID, "Phone shortcuts use mixed custom and built-in order")
        let relaunched = CustomPhraseLibrary(root: orderRoot)
        check(relaunched.sortableShortcuts.map(\.id) == reordered, "All shortcut positions survive relaunch")
        check(relaunched.shortcuts(including: PhraseShortcut.riderTexts).first?.id == PhraseShortcut.saved(secondOrdered).id, "Rider mode filters unrelated phrases while retaining saved order")
        check(orderSyntheses == 0, "Sorting never invokes speech synthesis")
        check(try orderStore.load() == [firstOrdered, secondOrdered], "Sorting preserves phrase identity, creation time, and audio directory")
        for phrase in [firstOrdered, secondOrdered] {
            check(try Data(contentsOf: orderStore.audioURL(for: phrase, voice: .female)) == female && Data(contentsOf: orderStore.audioURL(for: phrase, voice: .male)) == male, "Sorting preserves both audio files byte for byte")
        }
        let previousFile = try Data(contentsOf: orderRoot.appendingPathComponent("order.json"))
        for invalid in [Array(reordered.dropLast()), reordered + ["unknown"], [reordered[0]] + Array(reordered.dropLast()), reordered.dropLast() + ["unknown"]] {
            check(!orderedLibrary.reorder(Array(invalid)), "Missing, extra, duplicate, or foreign identity is rejected")
            check(try Data(contentsOf: orderRoot.appendingPathComponent("order.json")) == previousFile, "Rejected sort preserves disk order")
            check(orderedLibrary.sortableShortcuts.map(\.id) == reordered, "Rejected sort preserves visible order")
        }
        let changed = try orderStore.save(text: "第二句已修改", female: female, male: male, replacing: secondOrdered.id)
        orderedLibrary.reload()
        check(orderedLibrary.phrases.first == changed && orderedLibrary.sortableShortcuts.map(\.id) == reordered, "Editing phrase text retains its sorted position")
        let third = try orderStore.save(text: "新添一句", female: female, male: male)
        orderedLibrary.reload()
        check(orderedLibrary.sortableShortcuts.last?.id == PhraseShortcut.saved(third).id, "New phrases append without disturbing the chosen order")
        orderedLibrary.delete(firstOrdered)
        check(orderedLibrary.phrases.map(\.id) == [secondOrdered.id, third.id], "Deleting a sorted phrase preserves remaining positions")
        check(orderedLibrary.reorder(orderedLibrary.sortableShortcuts.map(\.id)), "Sorting after add and delete prunes stale saved identities")
        let duplicateSystem = try orderStore.save(text: PhraseShortcut.phoneTexts[0], female: female, male: male)
        orderedLibrary.reload()
        let matching = orderedLibrary.shortcuts(including: PhraseShortcut.phoneTexts).filter { $0.text == duplicateSystem.text }
        check(matching.count == 1 && matching[0].custom?.id == duplicateSystem.id, "Duplicate wording shows the custom version only in playback shortcuts")
        orderedLibrary.delete(duplicateSystem)
        check(orderedLibrary.shortcuts(including: PhraseShortcut.phoneTexts).contains { $0.id == PhraseShortcut.builtIn(duplicateSystem.text).id }, "Deleting a custom duplicate restores the built-in shortcut")
        let damagedOrder = Data("unreadable order, preserve me".utf8)
        try damagedOrder.write(to: orderRoot.appendingPathComponent("order.json"))
        orderedLibrary.reload()
        check(orderedLibrary.orderError != nil && !orderedLibrary.phrases.isEmpty, "Unreadable ordering remains separate from playable phrase data")
        check(!orderedLibrary.reorder(orderedLibrary.sortableShortcuts.map(\.id)), "Corrupt ordering cannot be silently replaced")
        check(try Data(contentsOf: orderRoot.appendingPathComponent("order.json")) == damagedOrder, "Corrupt original ordering file remains recoverable")
        let blockedRoot = root.appendingPathComponent("unwritable-library")
        try Data("A file prevents creating the storage directory".utf8).write(to: blockedRoot)
        let blockedLibrary = CustomPhraseLibrary(root: blockedRoot)
        let beforeFailure = blockedLibrary.sortableShortcuts.map(\.id)
        let afterRetry = Array(beforeFailure.reversed())
        check(!blockedLibrary.reorder(afterRetry), "An actual filesystem write failure rejects the new order")
        check(blockedLibrary.sortableShortcuts.map(\.id) == beforeFailure && blockedLibrary.orderError != nil, "Write failure leaves visible order unchanged with a clear error")
        try FileManager.default.removeItem(at: blockedRoot)
        check(blockedLibrary.reorder(afterRetry), "A failed save can be retried after storage becomes available")
        check(CustomPhraseLibrary(root: blockedRoot).sortableShortcuts.map(\.id) == afterRetry, "Retried order survives a fresh library instance")
        print("Final total: \(count) custom-phrase regression checks passed.")
    }
}
