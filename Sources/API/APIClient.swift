import Foundation

class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.requestTimeout
        config.timeoutIntervalForResource = Constants.API.uploadTimeout
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = .prettyPrinted
    }

    // MARK: - Generic Request Methods
    func request<T: Decodable>(
        method: HTTPMethod,
        url: URL,
        headers: [String: String],
        body: Data? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        if let body = body {
            request.httpBody = body
        }

        Logger.debug("API request sent", category: Logger.api)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Log response arrival without response content
        Logger.debug("API response received", category: Logger.api)

        // Handle errors
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.apiError(errorMessage, httpResponse.statusCode)
        }

        // Decode response
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            Logger.error("Response decoding failed", category: Logger.api)
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func upload<T: Decodable>(
        url: URL,
        headers: [String: String],
        fileURL: URL,
        paramName: String,
        otherParams: [String: String]
    ) async throws -> T {
        let boundary = UUID().uuidString
        let request = try createMultipartRequest(
            url: url,
            boundary: boundary,
            headers: headers,
            fileURL: fileURL,
            paramName: paramName,
            otherParams: otherParams
        )

        Logger.debug("Multipart upload sent", category: Logger.api)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        Logger.debug("API response received", category: Logger.api)

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Upload failed"
            throw APIError.apiError(errorMessage, httpResponse.statusCode)
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods
    func createMultipartRequest(
        url: URL,
        boundary: String,
        headers: [String: String],
        fileURL: URL,
        paramName: String,
        otherParams: [String: String]
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8) ?? Data())
        let contentType: String
        switch fileURL.pathExtension.lowercased() {
        case "wav": contentType = "audio/wav"
        case "mp3": contentType = "audio/mpeg"
        case "m4a": contentType = "audio/mp4"
        default: contentType = "application/octet-stream"
        }
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8) ?? Data())
        body.append(try Data(contentsOf: fileURL))

        body.append("\r\n".data(using: .utf8) ?? Data())

        // Add other parameters
        for (key, value) in otherParams {
            body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) ?? Data())
            body.append("\(value)\r\n".data(using: .utf8) ?? Data())
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())

        request.httpBody = body
        return request
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
