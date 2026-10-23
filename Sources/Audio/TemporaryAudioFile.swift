import Foundation

/// Removes a recording once processing has finished, including failed requests.
enum TemporaryAudioFile {
    static func withCleanup<T>(at fileURL: URL, operation: () async throws -> T) async rethrows -> T {
        defer {
            AudioProcessor.cleanupAudioFile(fileURL)
        }
        return try await operation()
    }
}
