import Foundation
import os.log

struct Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.axelahrens.speechtotext"

    enum LogLevel: String {
        case debug = "🔵 DEBUG"
        case info = "🟢 INFO"
        case warning = "🟡 WARNING"
        case error = "🔴 ERROR"
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

    // MARK: - Private Logging Function
    private static func log(
        _ message: String,
        level: LogLevel,
        category: OSLog
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(level.rawValue): \(message)"

        // Console Output
        print(logMessage)

        // OSLog Output
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

        // File Logging (optional)
        if shouldLogToFile {
            writeToFile(logMessage)
        }
    }

    // MARK: - File Logging
    private static var shouldLogToFile: Bool {
        Foundation.UserDefaults.standard.bool(forKey: Constants.UserDefaults.enableLoggingKey)
    }

    private static func writeToFile(_ message: String) {
        DispatchQueue.global(qos: .background).async {
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
                    if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: fileURL)
                }
            }
        }
    }
}
