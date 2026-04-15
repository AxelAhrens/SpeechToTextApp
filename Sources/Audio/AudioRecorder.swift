import AVFoundation
import Combine

@Observable
final class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession
    private var audioURL: URL?
    private var timer: Timer?

    // Observable Properties
    var isRecording: Bool = false
    var recordingDuration: TimeInterval = 0
    var recordingError: String? = nil

    // Subject for publishing events
    let recordingFinished = PassthroughSubject<URL, Error>()

    override init() {
        audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
    }

    deinit {
        stopRecording()
        timer?.invalidate()
    }

    // MARK: - Public Methods
    func startRecording() {
        requestMicrophonePermission { [weak self] granted in
            guard granted else {
                self?.recordingError = "Mikrofon-Zugriff verweigert"
                Logger.error("Mikrofon-Zugriff verweigert", category: Logger.audio)
                return
            }

            DispatchQueue.main.async {
                self?.beginRecording()
            }
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil

        let url = audioURL
        Logger.info("Aufnahme gestoppt: \(url?.lastPathComponent ?? "unknown")", category: Logger.audio)

        return url
    }

    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            Logger.info("Audio-Session konfiguriert", category: Logger.audio)
        } catch {
            Logger.error("Audio-Session Setup fehlgeschlagen: \(error.localizedDescription)", category: Logger.audio)
            recordingError = "Audio-Setup fehlgeschlagen"
        }
    }

    private func beginRecording() {
        let fileName = "recording_\(UUID().uuidString).m4a"
        audioURL = Constants.tempAudioDirectory.appendingPathComponent(fileName)

        guard let audioURL = audioURL else {
            recordingError = "Fehler beim Erstellen der Aufnahmedatei"
            return
        }

        // Create temp directory if needed
        try? FileManager.default.createDirectory(
            at: Constants.tempAudioDirectory,
            withIntermediateDirectories: true
        )

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Constants.Audio.sampleRate,
            AVNumberOfChannelsKey: Constants.Audio.channels,
            AVEncoderBitRateKey: Constants.Audio.bitRate,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self

            if audioRecorder?.record() ?? false {
                isRecording = true
                recordingDuration = 0
                recordingError = nil
                startTimer()
                Logger.info("Aufnahme gestartet: \(fileName)", category: Logger.audio)
            } else {
                recordingError = "Aufnahme konnte nicht gestartet werden"
                Logger.error("Aufnahme konnte nicht gestartet werden", category: Logger.audio)
            }
        } catch {
            recordingError = error.localizedDescription
            Logger.error("Fehler beim Erstellen der Aufnahme: \(error.localizedDescription)", category: Logger.audio)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }

            self.recordingDuration += 0.1

            // Limit recording to Constants.Duration.maxRecordingDuration
            if self.recordingDuration >= Constants.Duration.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            completion(granted)
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            if let audioURL = audioURL {
                Logger.info("Aufnahme abgeschlossen erfolgreich: \(audioURL.lastPathComponent)", category: Logger.audio)
                recordingFinished.send(audioURL)
            }
        } else {
            let error = NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aufnahme fehlgeschlagen"])
            Logger.error("Aufnahme fehlgeschlagen", category: Logger.audio)
            recordingFinished.send(completion: .failure(error))
        }

        isRecording = false
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            recordingError = error.localizedDescription
            Logger.error("Audio-Fehler: \(error.localizedDescription)", category: Logger.audio)
        }
        isRecording = false
    }
}

// MARK: - Audio Utilities
extension AudioRecorder {
    static func getRecordingPermissionStatus() -> AVAudioSession.RecordPermission {
        AVAudioSession.sharedInstance().recordPermission
    }

    static func isMicrophoneAvailable() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        return audioSession.availableInputs?.contains { $0.portType == .builtInMic } ?? false
    }
}
