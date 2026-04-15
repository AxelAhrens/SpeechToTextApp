import AVFoundation
import Combine

@Observable
final class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioURL: URL?
    private var timer: Timer?

    var isRecording: Bool = false
    var recordingDuration: TimeInterval = 0
    var recordingError: String? = nil

    let recordingFinished = PassthroughSubject<URL, Error>()

    override init() {
        super.init()
    }

    deinit {
        _ = stopRecording()
        timer?.invalidate()
    }

    func startRecording() {
        requestMicrophonePermission { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.recordingError = "Mikrofon-Zugriff verweigert"
                Logger.error("Mikrofon-Zugriff verweigert. Bitte in Systemeinstellungen > Datenschutz > Mikrofon aktivieren.", category: Logger.audio)
                return
            }

            DispatchQueue.main.async {
                self.beginRecording()
            }
        }
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil

        let url = audioURL
        Logger.info("Aufnahme gestoppt: \(url?.lastPathComponent ?? "unknown"), Dauer: \(String(format: "%.1f", recordingDuration))s", category: Logger.audio)

        return url
    }

    private func beginRecording() {
        let fileName = "recording_\(UUID().uuidString).m4a"
        let tempDir = Constants.tempAudioDirectory
        audioURL = tempDir.appendingPathComponent(fileName)

        guard let audioURL = audioURL else {
            recordingError = "Fehler beim Erstellen der Aufnahmedatei"
            Logger.error("audioURL ist nil", category: Logger.audio)
            return
        }

        // Temp-Verzeichnis erstellen
        do {
            try FileManager.default.createDirectory(
                at: tempDir,
                withIntermediateDirectories: true
            )
            Logger.debug("Temp-Verzeichnis bereit: \(tempDir.path)", category: Logger.audio)
        } catch {
            recordingError = "Temp-Verzeichnis konnte nicht erstellt werden"
            Logger.error("Temp-Verzeichnis erstellen fehlgeschlagen: \(error.localizedDescription)", category: Logger.audio)
            return
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Constants.Audio.sampleRate,
            AVNumberOfChannelsKey: Constants.Audio.channels,
            AVEncoderBitRateKey: Constants.Audio.bitRate,
        ]

        // AVAudioRecorder erstellen
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            Logger.debug("AVAudioRecorder erstellt: \(audioURL.lastPathComponent)", category: Logger.audio)
        } catch {
            recordingError = "AVAudioRecorder konnte nicht erstellt werden: \(error.localizedDescription)"
            Logger.error("AVAudioRecorder init fehlgeschlagen: \(error.localizedDescription)", category: Logger.audio)
            return
        }

        // Vorbereiten (reserviert Hardware-Ressourcen)
        guard audioRecorder?.prepareToRecord() ?? false else {
            recordingError = "Mikrofon konnte nicht vorbereitet werden"
            Logger.error("prepareToRecord() fehlgeschlagen. Mikrofon eventuell nicht verfügbar oder belegt.", category: Logger.audio)
            return
        }
        Logger.debug("prepareToRecord() erfolgreich", category: Logger.audio)

        // Aufnahme starten
        guard audioRecorder?.record() ?? false else {
            recordingError = "Aufnahme konnte nicht gestartet werden"
            Logger.error("record() gab false zurück. Mögliche Ursachen: Mikrofon belegt, keine Berechtigung, Audio-Hardware-Problem.", category: Logger.audio)
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
                _ = self.stopRecording()
                Logger.warning("Max-Aufnahmedauer erreicht (\(Constants.Duration.maxRecordingDuration)s), automatisch gestoppt.", category: Logger.audio)
            }
        }
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            Logger.debug("Mikrofon-Berechtigung: bereits erteilt", category: Logger.audio)
            completion(true)
        case .notDetermined:
            Logger.info("Mikrofon-Berechtigung wird angefragt...", category: Logger.audio)
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Logger.info("Mikrofon-Berechtigung: \(granted ? "erteilt" : "verweigert")", category: Logger.audio)
                completion(granted)
            }
        case .denied:
            Logger.error("Mikrofon-Berechtigung: verweigert. Bitte in Systemeinstellungen aktivieren.", category: Logger.audio)
            completion(false)
        case .restricted:
            Logger.error("Mikrofon-Berechtigung: eingeschränkt (Kindersicherung o.ä.)", category: Logger.audio)
            completion(false)
        @unknown default:
            Logger.error("Mikrofon-Berechtigung: unbekannter Status", category: Logger.audio)
            completion(false)
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag, let audioURL = audioURL {
            Logger.info("Aufnahme abgeschlossen: \(audioURL.lastPathComponent)", category: Logger.audio)
            recordingFinished.send(audioURL)
        } else {
            Logger.error("Aufnahme fehlgeschlagen (successfully=false)", category: Logger.audio)
            let error = NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aufnahme fehlgeschlagen"])
            recordingFinished.send(completion: .failure(error))
        }
        isRecording = false
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            recordingError = error.localizedDescription
            Logger.error("Audio-Encoding-Fehler: \(error.localizedDescription)", category: Logger.audio)
        }
        isRecording = false
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
