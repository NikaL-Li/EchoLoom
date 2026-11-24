import Foundation

@main
struct OpeningTests {
    @MainActor static func main() throws {
        var count = 0
        func expect(_ result: Bool, _ text: String) { precondition(result,text); count += 1 }
        var w = OpeningWindow(requested: 0, delay: 2)
        let a = ObservedLine(id: UUID(), outgoing: true, connected: false, ended: false, held: false)
        var b = a; b.connected = true
        var end = b; end.ended = true
        var hold = b; hold.held = true
        var incoming = a; incoming.outgoing = false
        let other = ObservedLine(id: UUID(), outgoing: true, connected: true, ended: false, held: false)
        expect(w.check([], now: 1, accepted: true, ready: true) == .wait,"waiting for dial")
        expect(w.check([a], now: 2, accepted: true, ready: true) == .wait,"ringing never plays")
        expect(w.check([b], now: 3, accepted: true, ready: true) == .wait,"connection starts delay")
        let waiting = w
        expect(w.check([b], now: 5, accepted: false, ready: true) == .wait,"opening URL must succeed")
        expect(w.check([b], now: 5, accepted: true, ready: false) == .wait,"requires injection")
        expect(w.check([b], now: 6, accepted: true, ready: true) == .play,"one opening")
        expect(w.check([b], now: 6.5, accepted: true, ready: true) == .wait,"duplicate events stay quiet")
        for lines in [[end],[hold],[other],[incoming],[b,other],[]] {
            var s = waiting; expect(s.check(lines, now: 5, accepted: true, ready: true) == .cancel,"cancel ambiguous, held or ended call")
        }
        var late = waiting
        expect(late.check([b], now: 10, accepted: true, ready: true) == .cancel,"never play a late greeting")
        for (lines,t) in [([b],2.0),([a],16.0),([incoming],2.0)] {
            var s = OpeningWindow(requested: 0, delay: 2)
            expect(s.check(lines, now: t, accepted: true, ready: true) == .cancel,"must see timely outgoing ringing")
        }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("data.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let s = UniversalStore(file: file)
        _ = s.saveScene(EverydaySceneDraft(title: "保留的资料"))
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String:Any]
        json.removeValue(forKey: "openingSettings")
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        s.reload()
        expect(!s.loadFailed && s.data.scenes.first?.title == "保留的资料","old records survive")
        expect(s.data.preferences.communication == .spokenReply && !s.openings.automatic,"defaults")
        expect(s.updateOpenings { $0.automatic = true; $0.delay = 4; $0.contacts = [OpeningContact(name: "甲",number: "13800001234",phraseID:"special")] },"save preference")
        let restored = UniversalStore(file: file).openings
        expect(restored.automatic && restored.delay == 4,"persist settings")
        expect(restored.contact("+86 138-0000-1234")?.phraseID == "special","CN national/international exact match")
        expect(restored.contact("1234") == nil && restored.contact("+1 381 000 1234") == nil,"no suffix matching")
        expect(EverydaySceneDraft(phone: "555-1212").callablePhone?.number == "5551212", "scene and dialer agree on intact local numbers")
        expect(EverydaySceneDraft(phone: "1234").callablePhone == nil, "partial number stays disabled")
        expect(CustomerPhone("13800001234\n") == nil && CustomerPhone(universal: "123\n4567") == nil, "reject control characters before URL construction")
        try FileManager.default.removeItem(at: file)
        s.reload()
        expect(s.data.scenes.isEmpty && s.openings.contacts.isEmpty, "reloading a removed store must not resurrect private records")
        print("\(count) opening lifecycle and persistence checks passed.")
    }
}
