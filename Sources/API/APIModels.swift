import Foundation

// MARK: - Whisper API Models
struct WhisperTranscriptionRequest: Encodable {
    let file: String // Base64 encoded or file data
    let model: String = Constants.API.whisperModel
    let language: String = "de"
    let prompt: String?

    enum CodingKeys: String, CodingKey {
        case file
        case model
        case language
        case prompt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(file, forKey: .file)
        try container.encode(model, forKey: .model)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(prompt, forKey: .prompt)
    }
}

struct WhisperTranscriptionResponse: Decodable {
    let text: String
}

// MARK: - Claude API Models
struct ClaudeMessageRequest: Encodable {
    let model: String = Constants.API.claudeModel
    let max_tokens: Int = 1024
    let system: String?
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case max_tokens
        case system
        case messages
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(max_tokens, forKey: .max_tokens)
        try container.encodeIfPresent(system, forKey: .system)
        try container.encode(messages, forKey: .messages)
    }
}

struct ClaudeMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
}

struct ClaudeMessageResponse: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String
    }

    let id: String
    let type: String
    let role: String
    let content: [Content]
    let model: String
    let stop_reason: String
    let usage: Usage

    var text: String {
        content.first(where: { $0.type == "text" })?.text ?? ""
    }
}

struct Usage: Decodable {
    let input_tokens: Int
    let output_tokens: Int
}

// MARK: - Error Models
enum APIError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case decodingError(String)
    case networkError(String)
    case apiError(String, Int) // message, statusCode
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidRequest:
            return "Ungültige Anfrage"
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .decodingError(let message):
            return "Dekodierungsfehler: \(message)"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .apiError(let message, let code):
            return "API-Fehler (\(code)): \(message)"
        case .unknownError:
            return "Unbekannter Fehler"
        }
    }
}

// MARK: - Generic Response Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let data: T?
    let error: APIErrorResponse?
}

struct APIErrorResponse: Decodable {
    let type: String
    let message: String
}
