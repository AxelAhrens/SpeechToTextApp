import Foundation

class WhisperAPI {
    static let shared = WhisperAPI()
    private let apiClient = APIClient.shared

    // MARK: - Transcription
    func transcribeAudio(
        fileURL: URL,
        apiKey: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw APIError.apiError("API Key is missing", 401)
        }

        // Validate audio file
        let (isValid, error) = AudioProcessor.validateAudioForWhisper(fileURL)
        guard isValid else {
            throw APIError.invalidRequest // error: \(error ?? "Unknown")")
        }

        let url = Constants.API.openaiBaseURL.appendingPathComponent("audio/transcriptions")

        var headers: [String: String] = [
            "Authorization": "Bearer \(apiKey)",
        ]

        Logger.info("Starting transcription: \(fileURL.lastPathComponent)", category: Logger.api)

        let response: WhisperTranscriptionResponse = try await apiClient.upload(
            url: url,
            headers: headers,
            fileURL: fileURL,
            paramName: "file"
        )

        Logger.info("Transcription complete: \(response.text.prefix(100))...", category: Logger.api)

        // Cleanup audio file after successful transcription
        DispatchQueue.global(qos: .background).async {
            AudioProcessor.cleanupAudioFile(fileURL)
        }

        return response.text
    }
}
