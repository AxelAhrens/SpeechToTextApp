import AppKit
import Combine

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var eventMonitor: Any?
    private let hotkeyMonitor = HotkeyMonitor.shared

    let hotkeyTriggered = PassthroughSubject<TranscriptionMode, Never>()

    // MARK: - Setup
    func registerHotkeys() {
        hotkeyMonitor.startMonitoring()
        Logger.info("Global hotkeys registered (NSEvent monitoring)", category: Logger.general)
    }

    func unregisterHotkeys() {
        hotkeyMonitor.stopMonitoring()
        Logger.info("Global hotkeys unregistered", category: Logger.general)
    }
}

// MARK: - Event Monitoring
class HotkeyMonitor {
    static let shared = HotkeyMonitor()

    private var eventMonitor: Any?
    let hotkeyTriggered = PassthroughSubject<TranscriptionMode, Never>()

    func startMonitoring() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        Logger.info("Hotkey monitoring started", category: Logger.general)
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let commandKeyPressed = event.modifierFlags.contains(.command)
        let shiftKeyPressed = event.modifierFlags.contains(.shift)

        guard commandKeyPressed, shiftKeyPressed else { return }

        let mode: TranscriptionMode?

        switch event.keyCode {
        case 18: // 1
            mode = .direct
        case 19: // 2
            mode = .polished
        case 20: // 3
            mode = .rageToPolite
        case 21: // 4
            mode = .socialMedia
        default:
            mode = nil
        }

        if let mode = mode {
            Logger.debug("Hotkey triggered: \(mode.displayName)", category: Logger.general)
            hotkeyTriggered.send(mode)
        }
    }

    func stopMonitoring() {
        Logger.info("Hotkey monitoring stopped", category: Logger.general)
    }
}
