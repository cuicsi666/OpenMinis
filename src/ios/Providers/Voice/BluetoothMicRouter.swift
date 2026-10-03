import Foundation
import AVFoundation

// MARK: - BluetoothMicRouter
//
// Routes voice-input capture to a connected Bluetooth headset's microphone (HFP)
// whenever one is attached, so dictation / voice input listens to the earpiece
// mic instead of the phone's built-in mic.
//
// iOS never routes recording to a Bluetooth mic on its own just because we set
// `.allowBluetooth` — AVAudioSession still prefers the built-in mic by default.
// We have to BOTH (a) allow Bluetooth in the session category options AND
// (b) explicitly `setPreferredInput` to the `.bluetoothHFP` port when present.
// When no Bluetooth mic is attached, these calls are no-ops and capture falls
// back to the system default (built-in) mic — i.e. behaviour is unchanged.

enum BluetoothMicRouter {

    /// The Bluetooth (HFP) microphone input port, if one is currently attached.
    /// `bluetoothHFP` is the Hands-Free/headset profile that exposes a real mic;
    /// A2DP (`.bluetoothA2DP`) is output-only and never appears as an input.
    static var bluetoothInput: AVAudioSessionPortDescription? {
        AVAudioSession.sharedInstance()
            .availableInputs?
            .first { $0.portType == .bluetoothHFP }
    }

    /// True when the CURRENT audio input route is the Bluetooth mic.
    /// Useful to surface a "listening via 🎧 Bluetooth mic" badge in the UI.
    static var isUsingBluetoothMic: Bool {
        let inputs = AVAudioSession.sharedInstance().currentRoute.inputs
        return inputs.contains { $0.portType == .bluetoothHFP }
    }

    /// Prefer the Bluetooth headset mic when one is attached. Must be called AFTER
    /// the session is active (`setActive(true)`) with a category that allows
    /// Bluetooth (`[.allowBluetooth]`). Returns true if a Bluetooth mic was found
    /// and selected.
    @discardableResult
    static func preferBluetoothMic() -> Bool {
        let session = AVAudioSession.sharedInstance()
        guard session.recordPermission != .denied else { return false }
        guard let bt = bluetoothInput else { return false }
        do {
            try session.setPreferredInput(bt)
            let hint = isUsingBluetoothMic ? "applied" : "set (route pending)"
            AppLogger(category: "BluetoothMic").info(
                "preferBluetoothMic → \(bt.portName) (\(String(describing: bt.portType.rawValue))) \(hint)")
            return true
        } catch {
            AppLogger(category: "BluetoothMic").error(
                "preferBluetoothMic FAILED: \(error.localizedDescription)")
            return false
        }
    }

    /// Drop the explicit input override and let the system pick (built-in mic).
    /// Call when a Bluetooth mic disappears mid-capture or when reconfiguring
    /// the session away from capture.
    static func clearBluetoothPreference() {
        _ = try? AVAudioSession.sharedInstance().setPreferredInput(nil)
    }
}