import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(Speech)
import Speech
#endif

struct YZGuideSystemPermissionQuery: YZGuidePermissionQuerying {
    func microphoneStatus() -> YZGuidePermissionRowState {
        #if canImport(UIKit) && canImport(AVFoundation)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .resolved(.authorized, restricted: false)
        case .denied:
            return .resolved(.denied, restricted: false)
        case .restricted:
            return .resolved(.denied, restricted: true)
        case .notDetermined:
            return .resolved(.notDetermined, restricted: false)
        @unknown default:
            return .failed
        }
        #else
        return .resolved(.notDetermined, restricted: false)
        #endif
    }

    func speechRecognitionStatus() -> YZGuidePermissionRowState {
        #if canImport(UIKit) && canImport(Speech)
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .resolved(.authorized, restricted: false)
        case .denied:
            return .resolved(.denied, restricted: false)
        case .restricted:
            return .resolved(.denied, restricted: true)
        case .notDetermined:
            return .resolved(.notDetermined, restricted: false)
        @unknown default:
            return .failed
        }
        #else
        return .resolved(.notDetermined, restricted: false)
        #endif
    }

    func openApplicationSettings() -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return false
        }
        Task { @MainActor in
            UIApplication.shared.open(url)
        }
        return true
        #else
        return false
        #endif
    }
}
