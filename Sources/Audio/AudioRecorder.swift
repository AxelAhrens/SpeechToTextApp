import AVFoundation

@Observable
final class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var pendingStartID: UUID?

    var isRecording: Bool = false
    var recordingDuration: TimeInterval = 0
    var recordingError: String? = nil

    override init() {
        super.init()
    }

    deinit {
        if let abandonedURL = stopRecording() {
            AudioProcessor.cleanupAudioFile(abandonedURL)
        }
        timer?.invalidate()
    }

    func startRecording() {
        guard !isRecording, pendingStartID == nil, audioRecorder == nil else { return }
        let requestID = UUID()
        pendingStartID = requestID
        requestMicrophonePermission { [weak self] granted in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.pendingStartID == requestID else { return }
                self.pendingStartID = nil
                guard granted else {
                    self.recordingError = "Mikrofon-Zugriff verweigert"
                    Logger.error("Mikrofon-Zugriff verweigert. Bitte in Systemeinstellungen > Datenschutz > Mikrofon aktivieren.", category: Logger.audio)
                    return
                }
                self.beginRecording()
            }
        }
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else {
            pendingStartID = nil
            return nil
        }
        let url = recorder.url
        // Transfer file ownership to the caller before stop() can trigger a delegate callback.
        audioRecorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
        recorder.stop()

        Logger.info("Aufnahme gestoppt", category: Logger.audio)

        return url
    }

    private func beginRecording() {
        guard !isRecording, audioRecorder == nil else { return }
        let fileName = "recording_\(UUID().uuidString).wav"
        let tempDir = Constants.tempAudioDirectory
        let audioURL = tempDir.appendingPathComponent(fileName)

        // Temp-Verzeichnis erstellen
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            recordingError = "Temp-Verzeichnis konnte nicht erstellt werden"
            Logger.error("Temp-Verzeichnis erstellen fehlgeschlagen: \(error.localizedDescription)", category: Logger.audio)
            return
        }

        // Schreibbarkeit prüfen
        guard FileManager.default.isWritableFile(atPath: tempDir.path) else {
            Logger.error("Temp-Verzeichnis nicht beschreibbar: \(tempDir.path)", category: Logger.audio)
            recordingError = "Temp-Verzeichnis nicht beschreibbar"
            return
        }

        // Linear PCM (WAV) -- zuverlässiger als AAC, wird von Whisper unterstützt
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: Constants.Audio.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]

        Logger.debug("Audio-Settings: WAV 16kHz 16bit Mono", category: Logger.audio)
        Logger.debug("Ziel-Datei: \(audioURL.path)", category: Logger.audio)

        // AVAudioRecorder erstellen
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            Logger.debug("AVAudioRecorder erstellt", category: Logger.audio)
        } catch {
            recordingError = "AVAudioRecorder Fehler: \(error.localizedDescription)"
            Logger.error("AVAudioRecorder init fehlgeschlagen: \(error.localizedDescription)", category: Logger.audio)
            Logger.error("NSError details: \(error)", category: Logger.audio)
            if FileManager.default.fileExists(atPath: audioURL.path) {
                AudioProcessor.cleanupAudioFile(audioURL)
            }
            return
        }

        // Vorbereiten
        let prepared = audioRecorder?.prepareToRecord() ?? false
        if !prepared {
            // Fallback: Trotzdem record() versuchen
            Logger.warning("prepareToRecord() gab false zurück, versuche record() direkt...", category: Logger.audio)
        } else {
            Logger.debug("prepareToRecord() erfolgreich", category: Logger.audio)
        }

        // Aufnahme starten
        guard audioRecorder?.record() ?? false else {
            recordingError = "Aufnahme konnte nicht gestartet werden"
            Logger.error("record() gab false zurück.", category: Logger.audio)
            Logger.error("audioRecorder.isRecording: \(audioRecorder?.isRecording ?? false)", category: Logger.audio)
            Logger.error("audioRecorder.url: \(audioRecorder?.url.path ?? "nil")", category: Logger.audio)

            // Diagnose: Verfügbare Audio-Eingabegeräte loggen
            logAvailableAudioDevices()
            let failedRecorder = audioRecorder
            audioRecorder = nil
            failedRecorder?.stop()
            if FileManager.default.fileExists(atPath: audioURL.path) {
                AudioProcessor.cleanupAudioFile(audioURL)
            }
            return
        }

        isRecording = true
        recordingDuration = 0
        recordingError = nil
        startTimer()
        Logger.info("Aufnahme gestartet: \(fileName)", category: Logger.audio)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, self.isRecording else { return }

            self.recordingDuration += 0.1

            if self.recordingDuration >= Constants.Duration.maxRecordingDuration {
                if let abandonedURL = self.stopRecording() {
                    AudioProcessor.cleanupAudioFile(abandonedURL)
                }
                Logger.warning("Max-Aufnahmedauer erreicht, automatisch gestoppt.", category: Logger.audio)
            }
        }
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            Logger.debug("Mikrofon-Berechtigung: erteilt", category: Logger.audio)
            completion(true)
        case .notDetermined:
            Logger.info("Mikrofon-Berechtigung wird angefragt...", category: Logger.audio)
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Logger.info("Mikrofon-Berechtigung: \(granted ? "erteilt" : "verweigert")", category: Logger.audio)
                completion(granted)
            }
        case .denied:
            Logger.error("Mikrofon-Berechtigung: verweigert. Systemeinstellungen > Datenschutz > Mikrofon", category: Logger.audio)
            completion(false)
        case .restricted:
            Logger.error("Mikrofon-Berechtigung: eingeschränkt", category: Logger.audio)
            completion(false)
        @unknown default:
            Logger.error("Mikrofon-Berechtigung: unbekannter Status", category: Logger.audio)
            completion(false)
        }
    }

    private func logAvailableAudioDevices() {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        ).devices

        if devices.isEmpty {
            Logger.error("KEINE Audio-Eingabegeräte gefunden!", category: Logger.audio)
        } else {
            for device in devices {
                Logger.info("Audio-Gerät: \(device.localizedName) (ID: \(device.uniqueID))", category: Logger.audio)
            }
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard audioRecorder === recorder else { return }
        audioRecorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
        recordingError = flag ? "Aufnahme unerwartet beendet" : "Aufnahme fehlgeschlagen"
        AudioProcessor.cleanupAudioFile(recorder.url)
        Logger.error("Aufnahme ohne Verarbeitung beendet", category: Logger.audio)
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        guard audioRecorder === recorder else { return }
        audioRecorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
        recordingError = error?.localizedDescription ?? "Audio-Encoding-Fehler"
        recorder.stop()
        AudioProcessor.cleanupAudioFile(recorder.url)
        Logger.error("Audio-Encoding-Fehler", category: Logger.audio)
    }
}

extension AudioRecorder {
    static func isMicrophoneAvailable() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    static func microphonePermissionStatus() -> String {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return "Erteilt"
        case .denied: return "Verweigert"
        case .restricted: return "Eingeschränkt"
        case .notDetermined: return "Noch nicht angefragt"
        @unknown default: return "Unbekannt"
        }
    }
}
