import Foundation
import os.log

struct Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.axelahrens.speechtotext"

    enum LogLevel: String, Comparable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"

        var emoji: String {
            switch self {
            case .debug: return "🔵"
            case .info: return "🟢"
            case .warning: return "🟡"
            case .error: return "🔴"
            }
        }

        var rank: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            }
        }

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rank < rhs.rank
        }
    }

    // OSLog categories
    static let audio = OSLog(subsystem: subsystem, category: "Audio")
    static let api = OSLog(subsystem: subsystem, category: "API")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let general = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Logging Methods
    static func debug(_ message: String, category: OSLog = general) {
        log(message, level: .debug, category: category)
    }

    static func info(_ message: String, category: OSLog = general) {
        log(message, level: .info, category: category)
    }

    static func warning(_ message: String, category: OSLog = general) {
        log(message, level: .warning, category: category)
    }

    static func error(_ message: String, category: OSLog = general) {
        log(message, level: .error, category: category)
    }

    static func error(_ error: Error, category: OSLog = general) {
        log(error.localizedDescription, level: .error, category: category)
    }

    // MARK: - Main Log Function
    private static func log(
        _ message: String,
        level: LogLevel,
        category: OSLog
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(level.emoji) \(level.rawValue): \(message)"

        // Console
        print(logMessage)

        // OSLog
        switch level {
        case .debug:
            os_log("%{public}@", log: category, type: .debug, logMessage)
        case .info:
            os_log("%{public}@", log: category, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: category, type: .default, logMessage)
        case .error:
            os_log("%{public}@", log: category, type: .error, logMessage)
        }

        // File: Errors und Warnings IMMER, Rest nur wenn aktiviert
        if level >= .warning || fileLoggingEnabled {
            writeToFile(logMessage)
        }
    }

    // MARK: - File Logging
    private static var fileLoggingEnabled: Bool {
        Foundation.UserDefaults.standard.bool(forKey: Constants.UserDefaults.enableLoggingKey)
    }

    static func enableFileLogging() {
        Foundation.UserDefaults.standard.set(true, forKey: Constants.UserDefaults.enableLoggingKey)
        info("File-Logging aktiviert. Pfad: \(currentLogFilePath)", category: general)
    }

    static func disableFileLogging() {
        info("File-Logging deaktiviert", category: general)
        Foundation.UserDefaults.standard.set(false, forKey: Constants.UserDefaults.enableLoggingKey)
    }

    // Aktueller Logfile-Pfad (zum Anzeigen im UI)
    static var currentLogFilePath: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "\(dateFormatter.string(from: Date())).log"
        return Constants.logsDirectory.appendingPathComponent(filename).path
    }

    // Alle Logfiles auflisten
    static var allLogFiles: [URL] {
        let logDir = Constants.logsDirectory
        guard FileManager.default.fileExists(atPath: logDir.path) else { return [] }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: logDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []
        return files
            .filter { $0.pathExtension == "log" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    // Logfile-Inhalt lesen (z.B. für Fehlerreport)
    static func readCurrentLog() -> String {
        guard let data = FileManager.default.contents(atPath: currentLogFilePath),
              let content = String(data: data, encoding: .utf8) else {
            return "(Keine Logs vorhanden)"
        }
        return content
    }

    // Nur Errors aus aktuellem Log lesen
    static func readErrorsOnly() -> String {
        let content = readCurrentLog()
        let lines = content.components(separatedBy: "\n")
        let errors = lines.filter { $0.contains("ERROR") || $0.contains("WARNING") }
        return errors.isEmpty ? "(Keine Fehler heute)" : errors.joined(separator: "\n")
    }

    private static let fileWriteQueue = DispatchQueue(label: "com.axelahrens.speechtotext.logger", qos: .background)

    private static func writeToFile(_ message: String) {
        fileWriteQueue.async {
            let logDirectory = Constants.logsDirectory
            try? FileManager.default.createDirectory(
                at: logDirectory,
                withIntermediateDirectories: true
            )

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let filename = "\(dateFormatter.string(from: Date())).log"
            let fileURL = logDirectory.appendingPathComponent(filename)
            let logEntry = message + "\n"

            if let data = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        try? fileHandle.close()
                    }
                } else {
                    try? data.write(to: fileURL)
                }
            }
        }
    }

    // MARK: - Cleanup
    static func cleanupOldLogs(keepDays: Int = 7) {
        let logDir = Constants.logsDirectory
        guard FileManager.default.fileExists(atPath: logDir.path) else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -keepDays, to: Date()) ?? Date()

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: logDir,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let modDate = attributes[.modificationDate] as? Date,
                   modDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                    info("Altes Logfile gelöscht: \(file.lastPathComponent)", category: general)
                }
            }
        } catch {
            // Silently fail - don't log to avoid recursion
        }
    }

    // MARK: - App Lifecycle
    static func logAppStart() {
        let separator = String(repeating: "=", count: 60)
        writeToFile("\n\(separator)")
        writeToFile("APP START: \(ISO8601DateFormatter().string(from: Date()))")
        writeToFile("Logfile: \(currentLogFilePath)")
        writeToFile("\(separator)")

        info("App gestartet. Logfile: \(currentLogFilePath)", category: general)

        // Alte Logs aufräumen
        cleanupOldLogs()
    }

    static func logAppExit() {
        info("App beendet", category: general)
    }
}
