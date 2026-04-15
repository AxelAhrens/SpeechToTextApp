import Foundation

struct Constants {
    // MARK: - API Configuration
    struct API {
        static let anthropicBaseURL = URL(string: "https://api.anthropic.com/v1")!
        static let openaiBaseURL = URL(string: "https://api.openai.com/v1")!

        // Claude Model
        static let claudeModel = "claude-3-5-sonnet-20241022"

        // Whisper Model (für Speech-to-Text)
        static let whisperModel = "whisper-1"

        // Timeouts
        static let requestTimeout: TimeInterval = 60
        static let uploadTimeout: TimeInterval = 300
    }

    // MARK: - Audio Configuration
    struct Audio {
        static let sampleRate: Double = 16000
        static let channels: UInt32 = 1
        static let bitRate: UInt32 = 128000
        static let format = "aac"
    }

    // MARK: - UI Configuration
    struct UI {
        static let menuBarWidth: CGFloat = 300
        static let settingsWindowWidth: CGFloat = 500
        static let settingsWindowHeight: CGFloat = 400
    }

    // MARK: - Keychain Keys
    struct Keychain {
        static let apiKeyKey = "anthropic_api_key"
        static let openaiAPIKeyKey = "openai_api_key"
    }

    // MARK: - UserDefaults Keys
    struct UserDefaults {
        static let selectedModeKey = "selectedMode"
        static let languageKey = "language"
        static let enableLoggingKey = "enableLogging"
        static let launchAtLoginKey = "launchAtLogin"
    }

    // MARK: - File Paths
    static var tempAudioDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeechToTextApp", isDirectory: true)
    }

    static var logsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SpeechToTextApp/Logs", isDirectory: true)
    }

    // MARK: - Timeouts & Durations
    struct Duration {
        static let maxRecordingDuration: TimeInterval = 300 // 5 minutes
        static let minRecordingDuration: TimeInterval = 1.0  // 1 second
        static let apiTimeoutDuration: TimeInterval = 60.0   // 60 seconds
    }

    // MARK: - Prompts for Different Modes
    struct Prompts {
        static let polishedPrompt = """
        Du bist ein Deutsch-Lektor. Wandle den folgenden Text in flüssiges, grammatikalisch korrektes Schriftsdeutsch um.
        Behalte den ursprünglichen Sinn bei, verbessere aber Satzstruktur und Ausdruck.

        Text:
        """

        static let rageToPolitePrompt = """
        Du bist ein professioneller E-Mail-Verfasser. Der folgende Text wurde wütend eingesprochen.
        Wandle ihn in eine höfliche, professionelle deutsche E-Mail um.
        Behalte die Kernaussage bei, aber formuliere höflich und konstruktiv.

        Text:
        """

        static let socialMediaPrompt = """
        Du bist ein Social-Media-Experte. Füge dem folgenden Text passende und natürliche Emojis hinzu.
        Behalte den Originaltext unverändert bei, aber ergänze ihn mit Emojis an geeigneten Stellen.

        Text:
        """
    }
}
