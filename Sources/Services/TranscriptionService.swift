import Foundation
import Combine

@Observable
final class TranscriptionService {
    private let audioRecorder = AudioRecorder()
    private let accessibilityService = AccessibilityService.shared
    private let whisperAPI = WhisperAPI.shared
    private let claudeAPI = ClaudeAPI.shared

    var isProcessing: Bool = false
    var lastTranscription: String = ""
    var lastProcessedText: String = ""
    var error: AppError? = nil

    private var subscriptions = Set<AnyCancellable>()

    init() {
        setupRecorderSubscriptions()
    }

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
            let transcription = try await whisperAPI.transcribeAudio(
                fileURL: audioURL,
                apiKey: apiKey
            )

            lastTranscription = transcription
            Logger.info("Transcription: \(transcription.prefix(100))...", category: Logger.api)

            let processedText = try await processTextForMode(
                transcription,
                mode: mode,
                apiKey: apiKey
            )

            lastProcessedText = processedText

            try accessibilityService.insertText(processedText)
            Logger.info("Text successfully inserted", category: Logger.general)

        } catch let err as APIError {
            error = .transcriptionFailed(err.errorDescription ?? "Unknown API error")
            Logger.error("API Error: \(err.errorDescription ?? "Unknown")", category: Logger.api)

        } catch let err as AppError {
            error = err
            Logger.error("App Error: \(err.errorDescription ?? "Unknown")", category: Logger.general)

        } catch {
            let appErr = AppError.unknown(error.localizedDescription)
            self.error = appErr
            Logger.error("Unexpected error: \(error.localizedDescription)", category: Logger.general)
        }
    }

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

    private func setupRecorderSubscriptions() {
        audioRecorder.recordingFinished
            .sink { _ in
                Logger.debug("Recording finished", category: Logger.audio)
            } receiveValue: { _ in
                Logger.error("Recording error", category: Logger.audio)
            }
            .store(in: &subscriptions)
    }

    var isRecording: Bool {
        audioRecorder.isRecording
    }

    var recordingDuration: TimeInterval {
        audioRecorder.recordingDuration
    }

    func isMicrophoneAvailable() -> Bool {
        AudioRecorder.isMicrophoneAvailable()
    }
}
