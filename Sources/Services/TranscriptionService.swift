import Foundation
import Combine

@Observable
final class TranscriptionService {
    private let audioRecorder = AudioRecorder()
    private let accessibilityService = AccessibilityService.shared
    private let whisperAPI = WhisperAPI.shared
    private let claudeAPI = ClaudeAPI.shared

    // Observable state
    var isProcessing: Bool = false
    var lastTranscription: String = ""
    var lastProcessedText: String = ""
    var error: AppError? = nil

    private var subscriptions = Set<AnyCancellable>()

    init() {
        setupRecorderSubscriptions()
    }

    // MARK: - Main Flow
    func startTranscription(mode: TranscriptionMode, apiKey: String) {
        audioRecorder.startRecording()
    }

    func stopTranscriptionAndProcess(mode: TranscriptionMode, apiKey: String) async {
        guard let audioURL = audioRecorder.stopRecording() else {
            error = .recordingFailed("No audio recorded")
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Step 1: Transcribe audio
            let transcription = try await whisperAPI.transcribeAudio(
                fileURL: audioURL,
                apiKey: apiKey
            )

            lastTranscription = transcription
            Logger.info("Transcription: \(transcription.prefix(100))...", category: Logger.api)

            // Step 2: Process text based on mode
            let processedText = try await processTextForMode(
                transcription,
                mode: mode,
                apiKey: apiKey
            )

            lastProcessedText = processedText

            // Step 3: Insert text into focused application
            try accessibilityService.insertText(processedText)
            Logger.info("Text successfully inserted", category: Logger.general)

        } catch let err as APIError {
            error = .transcriptionFailed(err.errorDescription ?? "Unknown API error")
            Logger.error("API Error: \(err.errorDescription ?? "Unknown")", category: Logger.api)

        } catch let err as AppError {
            error = err
            Logger.error("App Error: \(err.errorDescription ?? "Unknown")", category: Logger.general)

        } catch {
            error = .unknown(error.localizedDescription)
            Logger.error("Unexpected error: \(error.localizedDescription)", category: Logger.general)
        }
    }

    // MARK: - Text Processing
    private func processTextForMode(
        _ text: String,
        mode: TranscriptionMode,
        apiKey: String
    ) async throws -> String {
        switch mode {
        case .direct:
            return text

        case .polished, .rageToPolite, .socialMedia:
            return try await claudeAPI.processText(
                text: text,
                mode: mode,
                apiKey: apiKey
            )
        }
    }

    // MARK: - Recorder Subscriptions
    private func setupRecorderSubscriptions() {
        audioRecorder.recordingFinished
            .sink { [weak self] url in
                // Handle completion if needed
                self?.Logger.debug("Recording finished: \(url.lastPathComponent)", category: Logger.audio)
            } receiveValue: { [weak self] error in
                self?.error = .recordingFailed(error.localizedDescription)
            }
            .store(in: &subscriptions)
    }

    // MARK: - State
    var isRecording: Bool {
        audioRecorder.isRecording
    }

    var recordingDuration: TimeInterval {
        audioRecorder.recordingDuration
    }

    // MARK: - Getters
    func getRecordingPermissionStatus() -> String {
        let status = AudioRecorder.getRecordingPermissionStatus()
        return status.debugDescription
    }

    func isMicrophoneAvailable() -> Bool {
        AudioRecorder.isMicrophoneAvailable()
    }
}

// MARK: - Extension for Logger access
extension TranscriptionService {
    private var Logger: Logger.Type {
        return Swift.Logger.self
    }
}
