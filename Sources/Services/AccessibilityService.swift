import AppKit
import Accessibility

class AccessibilityService {
    static let shared = AccessibilityService()

    private let clipboardService = ClipboardService.shared

    // MARK: - Accessibility Permissions
    static func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    static func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Accessibility-Berechtigung erforderlich"
        alert.informativeText = """
        Die App benötigt Accessibility-Zugriff um Text in andere Apps einzufügen.

        Bitte öffne Systemeinstellungen → Sicherheit & Datenschutz → Datenschutz → Accessibility
        und aktiviere SpeechToTextApp.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Systemeinstellungen öffnen")
        alert.addButton(withTitle: "Später")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Insert Text
    func insertText(_ text: String) throws {
        guard AXIsProcessTrusted() else {
            Logger.error("Accessibility permission not granted", category: Logger.general)
            throw AppError.accessibilityError("Accessibility permission not granted")
        }

        // Copy text to clipboard
        clipboardService.copyText(text)

        // Use keyboard shortcut to paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sendPasteCommand()
        }

        Logger.info("Text inserted via clipboard + paste command", category: Logger.general)
    }

    // MARK: - Keyboard Simulation
    private func sendPasteCommand() {
        // Create paste event (⌘V)
        let pasteKey: CGKeyCode = 9 // V key

        if let source = CGEventSource(stateID: .hidSystemState) {
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: pasteKey, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: pasteKey, keyDown: false)

            // Set Command modifier
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand

            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)

            Logger.debug("Paste command sent (⌘V)", category: Logger.general)
        }
    }

    // MARK: - Get Focused Application
    func getFocusedApplicationName() -> String? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        return focusedApp.localizedName
    }

    // MARK: - Helper
    func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
}
