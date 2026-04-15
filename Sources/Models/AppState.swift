import Foundation
import Observation

@Observable
final class AppState {
    // MARK: - Settings
    var apiKey: String = "" {
        didSet {
            saveAPIKey(apiKey)
        }
    }

    var selectedMode: TranscriptionMode = .direct {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: "selectedMode")
        }
    }

    // MARK: - Recording State
    var isRecording: Bool = false
    var recordingDuration: Double = 0
    var lastTranscription: String = ""

    // MARK: - Error Handling
    var lastError: AppError? = nil
    var showError: Bool = false

    init() {
        loadSettings()
    }

    // MARK: - Settings Persistence
    private func loadSettings() {
        if let savedKey = KeychainHelper.retrieve(key: "anthropic_api_key") {
            self.apiKey = savedKey
        }

        if let modeRaw = UserDefaults.standard.string(forKey: "selectedMode"),
           let mode = TranscriptionMode(rawValue: modeRaw) {
            self.selectedMode = mode
        }
    }

    private func saveAPIKey(_ key: String) {
        KeychainHelper.save(key: "anthropic_api_key", value: key)
    }

    // MARK: - Error Management
    func setError(_ error: AppError) {
        self.lastError = error
        self.showError = true
    }

    func clearError() {
        self.lastError = nil
        self.showError = false
    }
}

// MARK: - Enums
enum TranscriptionMode: String, CaseIterable {
    case direct = "direct"
    case polished = "polished"
    case rageToPolite = "rage_to_polite"
    case socialMedia = "social_media"

    var displayName: String {
        switch self {
        case .direct:
            return "Direkt"
        case .polished:
            return "Polished"
        case .rageToPolite:
            return "Wut → Höflich"
        case .socialMedia:
            return "Social Media"
        }
    }

    var description: String {
        switch self {
        case .direct:
            return "1:1 Transkription"
        case .polished:
            return "Flüssiges Schriftsdeutsch"
        case .rageToPolite:
            return "Wütendes Einsprechen → Professionelle Email"
        case .socialMedia:
            return "Text mit Emojis"
        }
    }
}

enum AppError: LocalizedError {
    case apiKeyMissing
    case recordingFailed(String)
    case transcriptionFailed(String)
    case accessibilityError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API Key nicht gespeichert"
        case .recordingFailed(let msg):
            return "Aufnahmefehler: \(msg)"
        case .transcriptionFailed(let msg):
            return "Transkriptionsfehler: \(msg)"
        case .accessibilityError(let msg):
            return "Accessibility-Fehler: \(msg)"
        case .unknown(let msg):
            return "Fehler: \(msg)"
        }
    }
}

// MARK: - Keychain Helper
struct KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8) ?? Data()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return string
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
