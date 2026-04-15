import AppKit

class ClipboardService {
    static let shared = ClipboardService()

    private let pasteboard = NSPasteboard.general

    // MARK: - Copy to Clipboard
    func copyText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        Logger.info("Text copied to clipboard: \(text.prefix(50))...", category: Logger.general)
    }

    // MARK: - Paste from Clipboard
    func pasteText() -> String? {
        guard let text = pasteboard.string(forType: .string) else {
            Logger.warning("Clipboard is empty or doesn't contain text", category: Logger.general)
            return nil
        }
        return text
    }

    // MARK: - Paste with Keyboard (Fallback)
    func pasteWithKeyboard() {
        let pasteCommand = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: pasteCommand) {
            scriptObject.executeAndReturnError(&error)
            if error != nil {
                Logger.error("AppleScript paste failed", category: Logger.general)
            }
        }
    }

    // MARK: - Clear Clipboard
    func clearClipboard() {
        pasteboard.clearContents()
        Logger.debug("Clipboard cleared", category: Logger.general)
    }
}
