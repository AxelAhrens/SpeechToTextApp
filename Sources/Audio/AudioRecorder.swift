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
        let fileName = "recording_\(UUID().uuidString).wav"
        let tempDir = Constants.tempAudioDirectory
        audioURL = tempDir.appendingPathComponent(fileName)

        guard let audioURL = audioURL else {
            recordingError = "Fehler beim Erstellen der Aufnahmedatei"
            Logger.error("audioURL ist nil", category: Logger.audio)
            return
        }

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
        if flag, let audioURL = audioURL {
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int64) ?? 0
            Logger.info("Aufnahme abgeschlossen: \(audioURL.lastPathComponent), Größe: \(fileSize / 1024)KB", category: Logger.audio)
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
