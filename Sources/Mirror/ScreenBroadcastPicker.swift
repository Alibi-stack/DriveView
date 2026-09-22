import ReplayKit
import SwiftUI

struct ScreenBroadcastPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: .zero)
        picker.preferredExtension = MirrorShared.broadcastExtensionBundleID
        picker.showsMicrophoneButton = false
        return picker
    }

    func updateUIView(
        _ uiView: RPSystemBroadcastPickerView,
        context: Context
    ) {}
}

