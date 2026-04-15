import AppKit
import Combine

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?
    private var activeMode: TranscriptionMode? = nil

    // Events
    let startRecording = PassthroughSubject<TranscriptionMode, Never>()
    let stopRecording = PassthroughSubject<TranscriptionMode, Never>()

    // Settings (wird von AppState gesetzt)
    var behavior: HotkeyBehavior = .toggle

    // MARK: - Lifecycle
    func register() {
        unregister()

        // KeyDown: Start (Toggle) oder Start (Push-to-Talk)
        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }

        // KeyUp: Stop bei Push-to-Talk
        keyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUp(event)
        }

        Logger.info("Hotkeys registriert (Modus: \(behavior.displayName))", category: Logger.general)
    }

    func unregister() {
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
        if let monitor = keyUpMonitor {
            NSEvent.removeMonitor(monitor)
            keyUpMonitor = nil
        }
        activeMode = nil
        Logger.info("Hotkeys deregistriert", category: Logger.general)
    }

    // MARK: - Key Handling
    private func handleKeyDown(_ event: NSEvent) {
        guard event.modifierFlags.contains(.command),
              event.modifierFlags.contains(.shift) else { return }

        // Ignore key repeats (wichtig für Push-to-Talk)
        guard !event.isARepeat else { return }

        guard let mode = modeForKeyCode(event.keyCode) else { return }

        switch behavior {
        case .toggle:
            handleToggle(mode: mode)
        case .pushToTalk:
            handlePushDown(mode: mode)
        }
    }

    private func handleKeyUp(_ event: NSEvent) {
        guard behavior == .pushToTalk else { return }

        guard event.modifierFlags.contains(.command),
              event.modifierFlags.contains(.shift) else { return }

        guard let mode = modeForKeyCode(event.keyCode) else { return }

        handlePushUp(mode: mode)
    }

    // MARK: - Toggle Modus
    private func handleToggle(mode: TranscriptionMode) {
        if let active = activeMode, active == mode {
            // Gleicher Hotkey nochmal = Stop
            Logger.info("Toggle STOP: \(mode.displayName)", category: Logger.general)
            activeMode = nil
            stopRecording.send(mode)
        } else {
            // Neuer Hotkey oder kein aktiver = Start
            if activeMode != nil {
                // Anderer Modus war aktiv, erst stoppen
                stopRecording.send(activeMode!)
            }
            Logger.info("Toggle START: \(mode.displayName)", category: Logger.general)
            activeMode = mode
            startRecording.send(mode)
        }
    }

    // MARK: - Push-to-Talk Modus
    private func handlePushDown(mode: TranscriptionMode) {
        guard activeMode == nil else { return }
        Logger.info("Push-to-Talk START: \(mode.displayName)", category: Logger.general)
        activeMode = mode
        startRecording.send(mode)
    }

    private func handlePushUp(mode: TranscriptionMode) {
        guard activeMode == mode else { return }
        Logger.info("Push-to-Talk STOP: \(mode.displayName)", category: Logger.general)
        activeMode = nil
        stopRecording.send(mode)
    }

    // MARK: - Key Mapping
    private func modeForKeyCode(_ keyCode: UInt16) -> TranscriptionMode? {
        switch keyCode {
        case 18: return .direct       // 1
        case 19: return .polished     // 2
        case 20: return .rageToPolite // 3
        case 21: return .socialMedia  // 4
        default: return nil
        }
    }

    // MARK: - State
    var isActive: Bool {
        activeMode != nil
    }

    var currentMode: TranscriptionMode? {
        activeMode
    }
}
