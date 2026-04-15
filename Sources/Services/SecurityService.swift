import Foundation
import Security
import ServiceManagement

struct SecurityService {
    static let shared = SecurityService()

    // MARK: - Keychain Operations
    func saveAPIKey(_ key: String, forService service: String = "SpeechToTextApp") {
        let data = key.data(using: .utf8) ?? Data()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: service,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        Logger.info("API Key saved to keychain", category: Logger.general)
    }

    func retrieveAPIKey(forService service: String = "SpeechToTextApp") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: service,
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

    func deleteAPIKey(forService service: String = "SpeechToTextApp") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: service,
        ]

        SecItemDelete(query as CFDictionary)
        Logger.info("API Key deleted from keychain", category: Logger.general)
    }

    // MARK: - Settings
    func savePreferences(_ dict: [String: Any]) {
        UserDefaults.standard.set(dict, forKey: "app_preferences")
    }

    func loadPreferences() -> [String: Any]? {
        UserDefaults.standard.dictionary(forKey: "app_preferences")
    }

    // MARK: - Launch at Login
    func enableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.register()
                Logger.info("Launch at login enabled", category: Logger.general)
            }
        } catch {
            Logger.error("Failed to enable launch at login: \(error.localizedDescription)", category: Logger.general)
        }
    }

    func disableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.unregister()
                Logger.info("Launch at login disabled", category: Logger.general)
            }
        } catch {
            Logger.error("Failed to disable launch at login: \(error.localizedDescription)", category: Logger.general)
        }
    }

    // MARK: - Validation
    func isValidAPIKey(_ key: String) -> Bool {
        !key.isEmpty && key.count > 10
    }
}
