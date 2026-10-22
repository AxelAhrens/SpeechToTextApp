import Foundation
import XCTest
@testable import SpeechToTextApp

final class APIClientUploadTests: XCTestCase {
    func testWhisperMultipartRequestIncludesAuthModelAndWavMetadata() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("upload-test-\(UUID().uuidString).wav")
        try Data("RIFF-test-audio".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let request = try APIClient.shared.createMultipartRequest(
            url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!,
            boundary: "test-boundary",
            headers: ["Authorization": "Bearer test-token"],
            fileURL: fileURL,
            paramName: "file",
            otherParams: ["model": "whisper-1", "language": "de"]
        )

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "multipart/form-data; boundary=test-boundary"
        )
        let body = try XCTUnwrap(request.httpBody.flatMap { String(data: $0, encoding: .utf8) })
        XCTAssertTrue(body.contains("Content-Type: audio/wav\r\n"))
        XCTAssertTrue(body.contains("name=\"model\"\r\n\r\nwhisper-1\r\n"))
        XCTAssertTrue(body.contains("name=\"language\"\r\n\r\nde\r\n"))
        XCTAssertTrue(body.contains("RIFF-test-audio"))
        XCTAssertTrue(body.hasSuffix("--test-boundary--\r\n"))
    }
}
