import XCTest
@testable import SpeechToTextApp

class AudioProcessorTests: XCTestCase {

    func testIsValidAudioFile() throws {
        // Create a mock audio file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_audio.m4a")

        // Write minimal audio data
        try Data().write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // This should fail because it's not actual audio
        let isValid = AudioProcessor.isValidAudioFile(tempURL)
        XCTAssertFalse(isValid, "Invalid audio file should be rejected")
    }

    func testGetAudioFileSize() throws {
        let testData = "test audio content".data(using: .utf8)!
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_size.m4a")

        try testData.write(to: tempURL)
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let size = AudioProcessor.getAudioFileSize(from: tempURL)
        XCTAssertEqual(size, Int64(testData.count), "File size should match")
    }

    func testCleanupAudioFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cleanup_test.m4a")

        try Data().write(to: tempURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path), "File should exist before cleanup")

        AudioProcessor.cleanupAudioFile(tempURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path), "File should be deleted after cleanup")
    }
}

class APIClientTests: XCTestCase {

    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }
}

class SecurityServiceTests: XCTestCase {

    func testIsValidAPIKey() {
        let validKey = "sk-1234567890abcdef1234567890"
        let invalidKey = "short"

        XCTAssertTrue(SecurityService.shared.isValidAPIKey(validKey), "Valid API key should pass")
        XCTAssertFalse(SecurityService.shared.isValidAPIKey(invalidKey), "Invalid API key should fail")
    }

    func testKeychainSaveAndRetrieve() {
        let testKey = "test_key_value"
        let service = "test_service"

        SecurityService.shared.saveAPIKey(testKey, forService: service)
        let retrieved = SecurityService.shared.retrieveAPIKey(forService: service)

        XCTAssertEqual(retrieved, testKey, "Retrieved key should match saved key")

        SecurityService.shared.deleteAPIKey(forService: service)
        let deleted = SecurityService.shared.retrieveAPIKey(forService: service)

        XCTAssertNil(deleted, "Key should be deleted")
    }
}

class AppStateTests: XCTestCase {

    func testTranscriptionModeDisplayNames() {
        XCTAssertEqual(TranscriptionMode.direct.displayName, "Direkt")
        XCTAssertEqual(TranscriptionMode.polished.displayName, "Polished")
        XCTAssertEqual(TranscriptionMode.rageToPolite.displayName, "Wut → Höflich")
        XCTAssertEqual(TranscriptionMode.socialMedia.displayName, "Social Media")
    }

    func testAppErrorDescriptions() {
        let error = AppError.apiKeyMissing
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.count > 0)
    }
}
