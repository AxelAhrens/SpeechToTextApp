import Foundation
import XCTest
@testable import SpeechToTextApp

final class TemporaryAudioFileTests: XCTestCase {
    func testFailedProcessingStillDeletesTemporaryRecording() async throws {
        struct ProcessingFailure: Error {}
        let directory = Constants.tempAudioDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("test-\(UUID().uuidString).wav")
        try Data("private speech".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        do {
            _ = try await TemporaryAudioFile.withCleanup(at: file) { () async throws -> String in
                XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
                throw ProcessingFailure()
            }
            XCTFail("Expected processing to fail")
        } catch is ProcessingFailure {
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        }
    }
}
