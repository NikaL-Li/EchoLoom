#if DEBUG
import SwiftUI

private struct YZPreviewPermissionQuery: YZGuidePermissionQuerying {
    let microphone: YZGuidePermissionRowState
    let speechRecognition: YZGuidePermissionRowState

    func microphoneStatus() -> YZGuidePermissionRowState {
        microphone
    }

    func speechRecognitionStatus() -> YZGuidePermissionRowState {
        speechRecognition
    }

    func openApplicationSettings() -> Bool {
        true
    }
}

struct YZGuidePreviewProvider: PreviewProvider {
    static var previews: some View {
        Group {
            GuideView(
                query: YZPreviewPermissionQuery(
                    microphone: .resolved(.authorized, restricted: false),
                    speechRecognition: .resolved(.notDetermined, restricted: false)
                ),
                onBack: {}
            )
            .previewDisplayName("Default")

            GuideView(
                query: YZPreviewPermissionQuery(
                    microphone: .resolved(.denied, restricted: true),
                    speechRecognition: .failed
                ),
                onBack: {}
            )
            .previewDisplayName("Denied")
        }
    }
}
#endif