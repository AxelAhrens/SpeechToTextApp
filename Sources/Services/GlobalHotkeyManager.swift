import Carbon
import Combine

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var hotkeyRefs: [TranscriptionMode: EventHotKeyRef] = [:]
    private var eventMonitor: EventMonitorRef?

    let hotkeyTriggered = PassthroughSubject<TranscriptionMode, Never>()

    // MARK: - Setup
    func registerHotkeys() {
        registerHotkey(mode: .direct, keyCode: 18, modifiers: [.command, .shift]) // ⌘⇧1
        registerHotkey(mode: .polished, keyCode: 19, modifiers: [.command, .shift]) // ⌘⇧2
        registerHotkey(mode: .rageToPolite, keyCode: 20, modifiers: [.command, .shift]) // ⌘⇧3
        registerHotkey(mode: .socialMedia, keyCode: 21, modifiers: [.command, .shift]) // ⌘⇧4

        Logger.info("Global hotkeys registered", category: Logger.general)
    }

    func unregisterHotkeys() {
        hotkeyRefs.forEach { _, ref in
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
        Logger.info("Global hotkeys unregistered", category: Logger.general)
    }

    // MARK: - Private Methods
    private func registerHotkey(
        mode: TranscriptionMode,
        keyCode: UInt32,
        modifiers: [UInt32]
    ) {
        let modifierMask: UInt32 = modifiers.reduce(0) { $0 | $1 }

        var hotkey = EventHotKeyID()
        hotkey.signature = OSType(bitPattern: UInt32(ascii: "STxt"))
        hotkey.id = UInt32(mode.hashValue)

        var ref: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifierMask,
            hotkey,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr, let ref = ref else {
            Logger.error("Failed to register hotkey for mode: \(mode.displayName)", category: Logger.general)
            return
        }

        hotkeyRefs[mode] = ref
        Logger.info("Hotkey registered: \(mode.displayName) (\(keyCode))", category: Logger.general)
    }
}

// MARK: - Modifier Keys
extension GlobalHotkeyManager {
    enum ModifierKey: UInt32 {
        case command = 256 // cmdKey
        case shift = 512 // shiftKey
        case control = 2048 // controlKey
        case option = 524288 // optionKey
    }
}

// MARK: - Event Monitoring (Alternative implementation for macOS 10.15+)
class HotkeyMonitor {
    static let shared = HotkeyMonitor()

    private var eventMonitor: Any?
    let hotkeyTriggered = PassthroughSubject<TranscriptionMode, Never>()

    func startMonitoring() {
        #if os(macOS)
        // Using NSEvent for monitoring
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        Logger.info("Hotkey monitoring started", category: Logger.general)
        #endif
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
