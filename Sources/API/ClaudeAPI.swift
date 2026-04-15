import Foundation

class ClaudeAPI {
    static let shared = ClaudeAPI()
    private let apiClient = APIClient.shared

    // MARK: - Text Processing
    func processText(
        text: String,
        mode: TranscriptionMode,
        apiKey: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw APIError.apiError("API Key is missing", 401)
        }

        let prompt = getPromptForMode(mode)
        let systemPrompt = "Du bist ein hilfreicher Assistent. Antworte prägnant und direkt."

        let message = ClaudeMessage(
            role: "user",
            content: "\(prompt)\n\nText: \(text)"
        )

        let request = ClaudeMessageRequest(
            system: systemPrompt,
            messages: [message]
        )

        let url = Constants.API.anthropicBaseURL.appendingPathComponent("messages")

        let headers = createAuthHeaders(apiKey: apiKey)

        let body = try JSONEncoder().encode(request)

        Logger.info("Processing text with mode: \(mode.displayName)", category: Logger.api)

        let response: ClaudeMessageResponse = try await apiClient.request(
            method: .post,
            url: url,
            headers: headers,
            body: body
        )

        Logger.info("Processing complete. Tokens: \(response.usage.input_tokens) → \(response.usage.output_tokens)", category: Logger.api)

        return response.text
    }

    // MARK: - Helper Methods
    private func getPromptForMode(_ mode: TranscriptionMode) -> String {
        switch mode {
        case .direct:
            return "Gib den Text genau so wieder wie er wurde:"

        case .polished:
            return Constants.Prompts.polishedPrompt

        case .rageToPolite:
            return Constants.Prompts.rageToPolitePrompt

        case .socialMedia:
            return Constants.Prompts.socialMediaPrompt
        }
    }

    private func createAuthHeaders(apiKey: String) -> [String: String] {
        return [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        ]
    }
}
