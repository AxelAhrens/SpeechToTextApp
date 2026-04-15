import AVFoundation

struct AudioProcessor {
    static func getAudioDuration(from fileURL: URL) -> TimeInterval {
        let asset = AVAsset(url: fileURL)
        return asset.duration.seconds
    }

    static func getAudioFileSize(from fileURL: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            Logger.error("Fehler beim Abrufen der Dateigröße: \(error.localizedDescription)", category: Logger.audio)
            return 0
        }
    }

    static func isValidAudioFile(_ fileURL: URL) -> Bool {
        let asset = AVAsset(url: fileURL)
        
        let duration = asset.duration.seconds
        guard duration >= Constants.Duration.minRecordingDuration else {
            Logger.warning("Aufnahme zu kurz: \(duration)s (min: \(Constants.Duration.minRecordingDuration)s)", category: Logger.audio)
            return false
        }

        let fileSize = getAudioFileSize(from: fileURL)
        let fileSizeInMB = Double(fileSize) / (1024 * 1024)

        guard fileSizeInMB <= 25 else {
            Logger.warning("Aufnahme zu groß: \(fileSizeInMB)MB (max: 25MB)", category: Logger.audio)
            return false
        }

        return true
    }

    static func cleanupAudioFile(_ fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            Logger.info("Audio-Datei gelöscht: \(fileURL.lastPathComponent)", category: Logger.audio)
        } catch {
            Logger.error("Fehler beim Löschen der Audio-Datei: \(error.localizedDescription)", category: Logger.audio)
        }
    }

    static func cleanupOldAudioFiles(olderThanMinutes: Int = 60) {
        let fileManager = FileManager.default
        let tempDirectory = Constants.tempAudioDirectory

        guard fileManager.fileExists(atPath: tempDirectory.path) else {
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )

            let cutoffDate = Date().addingTimeInterval(-TimeInterval(olderThanMinutes * 60))

            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < cutoffDate {
                    try fileManager.removeItem(at: file)
                    Logger.info("Alte Audio-Datei gelöscht: \(file.lastPathComponent)", category: Logger.audio)
                }
            }
        } catch {
            Logger.error("Fehler beim Löschen alter Audio-Dateien: \(error.localizedDescription)", category: Logger.audio)
        }
    }

    static func getAudioMetadata(from fileURL: URL) -> [String: Any] {
        let asset = AVAsset(url: fileURL)
        let duration = asset.duration.seconds
        let fileSize = getAudioFileSize(from: fileURL)

        var metadata: [String: Any] = [
            "duration": duration,
            "fileSize": fileSize,
            "fileName": fileURL.lastPathComponent,
            "fileURL": fileURL.absoluteString,
        ]

        return metadata
    }

    static func validateAudioForWhisper(_ fileURL: URL) -> (isValid: Bool, error: String?) {
        guard fileURL.pathExtension == "m4a" || fileURL.pathExtension == "wav" || fileURL.pathExtension == "mp3" else {
            return (false, "Unsupported audio format. Supported: m4a, wav, mp3")
        }

        let fileSize = getAudioFileSize(from: fileURL)
        let fileSizeInMB = Double(fileSize) / (1024 * 1024)

        guard fileSizeInMB <= 25 else {
            return (false, "File too large: \(fileSizeInMB)MB (max: 25MB)")
        }

        let duration = getAudioDuration(from: fileURL)
        guard duration >= 0.5 else {
            return (false, "Recording too short: \(duration)s")
        }

        return (true, nil)
    }
}
