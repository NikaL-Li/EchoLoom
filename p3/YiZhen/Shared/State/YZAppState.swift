import Foundation
import Observation

@MainActor
@Observable
final class YZAppState {
    private(set) var scenes: [YZScene]
    private(set) var phases: [YZPhase]
    private(set) var messages: [YZMessage]
    private(set) var phrases: [YZPhrase]
    private(set) var selectedView: YZDialogView
    private(set) var selectedSceneID: YZScene.ID
    private(set) var selectedPhaseID: YZPhase.ID?
    private(set) var currentPhaseID: YZPhase.ID?

    private let phraseBaseline: YZPhraseBaseline
    private var sentSequence = 0

    init(
        session: YZDialogSession,
        selectedView: YZDialogView = .dialog,
        phraseBaseline: YZPhraseBaseline = .six
    ) {
        let orderedScenes = session.scenes.sorted { $0.order < $1.order }
        let orderedPhases = session.phases.sorted { $0.order < $1.order }
        let initialSceneID = orderedScenes.first(where: { $0.isSelected })?.id ?? orderedScenes.first?.id ?? ""
        let initialPhaseID = orderedPhases.first(where: { $0.isCurrent })?.id
            ?? YZMockData.defaultPhaseID(for: initialSceneID)
            ?? orderedPhases.first?.id

        self.scenes = orderedScenes
        self.phases = orderedPhases
        self.messages = YZMessageValidator.normalize(session.messages)
        self.phrases = session.phrases
        self.selectedView = selectedView
        self.selectedSceneID = initialSceneID
        self.selectedPhaseID = initialPhaseID
        self.currentPhaseID = initialPhaseID
        self.phraseBaseline = phraseBaseline
        refreshPhrases()
    }

    var selectedScene: YZScene? {
        scenes.first { $0.id == selectedSceneID }
    }

    var selectedPhase: YZPhase? {
        phases.first { $0.id == selectedPhaseID }
    }

    var emergencyBanner: YZEmergencyBanner {
        YZEmergencyBanner(
            text: YZMockData.emergencyBannerText,
            visible: selectedScene?.isEmergency ?? false,
            interactive: false
        )
    }

    func selectScene(_ id: YZScene.ID) {
        guard scenes.contains(where: { $0.id == id }), id != selectedSceneID else { return }
        selectedSceneID = id
        phases = YZMockData.phases(for: id)
        selectedPhaseID = defaultPhaseID(for: id)
        currentPhaseID = selectedPhaseID
        refreshPhrases()
    }

    func selectPhase(_ id: YZPhase.ID) {
        guard phases.contains(where: { $0.id == id }), id != selectedPhaseID else { return }
        selectedPhaseID = id
        currentPhaseID = id
        refreshPhrases()
    }

    func selectView(_ view: YZDialogView) {
        guard view != selectedView else { return }
        selectedView = view
    }

    func phases(for sceneID: YZScene.ID) -> [YZPhase] {
        YZMockData.phases(for: sceneID)
    }

    func navStyle(of sceneID: YZScene.ID) -> YZNavStyle {
        YZMockData.navStyle(of: sceneID)
    }

    func defaultPhaseID(for sceneID: YZScene.ID) -> YZPhase.ID? {
        YZMockData.defaultPhaseID(for: sceneID)
    }

    @discardableResult
    func sendMineText(_ raw: String) -> YZMessage.ID? {
        guard let text = YZComposerRules.normalizedSendText(raw) else { return nil }
        sentSequence += 1
        let lastDate = messages.last?.createdAt ?? Date(timeIntervalSince1970: 0)
        let createdAt = max(Date(), lastDate)
        let message = YZMessage(
            id: "mine.c\(sentSequence)",
            direction: .mine,
            text: text,
            statusText: YZComposerStrings.sentStatusText,
            createdAt: createdAt
        )
        messages = YZMessageValidator.normalize(messages + [message])
        return messages.contains(where: { $0.id == message.id }) ? message.id : nil
    }

    func replaceBaseline(messages: [YZMessage]) {
        self.messages = YZMessageValidator.normalize(messages)
    }

    private func refreshPhrases() {
        guard phraseBaseline == .six else {
            phrases = []
            return
        }
        guard let phaseID = selectedPhaseID else {
            phrases = []
            return
        }
        phrases = YZMockData.phrases(sceneID: selectedSceneID, phaseID: phaseID)
    }
}