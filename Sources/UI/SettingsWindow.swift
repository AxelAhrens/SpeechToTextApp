import SwiftUI

struct SettingsWindow: View {
    @State var appState: AppState
    @State private var showAPIKeyField: Bool = false
    @State private var fileLoggingEnabled: Bool = Foundation.UserDefaults.standard.bool(forKey: Constants.UserDefaults.enableLoggingKey)

    var body: some View {
        TabView {
            // MARK: - API Settings Tab
            VStack(spacing: 16) {
                GroupBox(label: Label("Anthropic API", systemImage: "key.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Key für Claude Transkription und Text-Verarbeitung")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if showAPIKeyField {
                            SecureField("API Key", text: $appState.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .monospaced()

                            HStack(spacing: 8) {
                                Button(action: { showAPIKeyField = false }) {
                                    Text("Verbergen")
                                }
                                .buttonStyle(.bordered)

                                Button(action: openAnthropicConsole) {
                                    Text("API Console öffnen")
                                }
                                .buttonStyle(.bordered)

                                Spacer()

                                if !appState.apiKey.isEmpty {
                                    Label("Gespeichert", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        } else {
                            Button(action: { showAPIKeyField = true }) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    if appState.apiKey.isEmpty {
                                        Text("API Key eingeben")
                                    } else {
                                        Text("API Key ändern")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }

                GroupBox(label: Label("Transkription", systemImage: "quote.bubble")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sprache")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Picker("Sprache", selection: .constant("de")) {
                            Text("Deutsch").tag("de")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.segmented)

                        Divider()

                        Text("Audio-Format")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            Text("Sample Rate: 16kHz")
                                .font(.caption)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(4)

                            Text("Mono")
                                .font(.caption)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(4)

                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                }

                Spacer()
            }
            .padding()
            .tabItem {
                Label("API", systemImage: "gear")
            }

            // MARK: - Hotkeys Tab
            VStack(spacing: 16) {
                GroupBox(label: Label("Verhalten", systemImage: "hand.tap")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Hotkey-Modus", selection: $appState.hotkeyBehavior) {
                            ForEach(HotkeyBehavior.allCases, id: \.self) { behavior in
                                Text(behavior.displayName).tag(behavior)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appState.hotkeyBehavior) { _, newValue in
                            GlobalHotkeyManager.shared.behavior = newValue
                            GlobalHotkeyManager.shared.register()
                        }

                        HStack(spacing: 8) {
                            Image(systemName: appState.hotkeyBehavior == .toggle ? "arrow.triangle.2.circlepath" : "hand.point.down.fill")
                                .foregroundColor(.blue)
                            Text(appState.hotkeyBehavior.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }

                GroupBox(label: Label("Globale Tastenkürzel", systemImage: "keyboard")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HotKeyRow(
                            mode: "Direkt",
                            hotkey: "⌘⇧1",
                            description: "1:1 Transkription"
                        )

                        Divider()

                        HotKeyRow(
                            mode: "Polished",
                            hotkey: "⌘⇧2",
                            description: "Flüssiges Schriftsdeutsch"
                        )

                        Divider()

                        HotKeyRow(
                            mode: "Wut → Höflich",
                            hotkey: "⌘⇧3",
                            description: "In professionelle Email umwandeln"
                        )

                        Divider()

                        HotKeyRow(
                            mode: "Social Media",
                            hotkey: "⌘⇧4",
                            description: "Text mit Emojis versehen"
                        )
                    }
                    .padding(.vertical, 8)
                }

                Text("Hotkeys funktionieren systemweit. Accessibility-Berechtigung erforderlich.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Hotkeys", systemImage: "keyboard")
            }

            // MARK: - Permissions Tab
            VStack(spacing: 16) {
                GroupBox(label: Label("Berechtigungen", systemImage: "lock.shield")) {
                    VStack(alignment: .leading, spacing: 16) {
                        PermissionRow(
                            icon: "mic",
                            title: "Mikrofon",
                            description: "Zum Aufnehmen von Audio",
                            isGranted: checkMicrophonePermission()
                        )

                        Divider()

                        PermissionRow(
                            icon: "hand.raised",
                            title: "Accessibility",
                            description: "Um Text in andere Apps einzufügen",
                            isGranted: checkAccessibilityPermission()
                        )

                        Divider()

                        PermissionRow(
                            icon: "clock",
                            title: "Login Item",
                            description: "App startet automatisch mit macOS",
                            isGranted: true // Implement checking
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox(label: Label("Datenschutz", systemImage: "shield.text.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Keys werden sicher im Keychain gespeichert und nicht in Logs protokolliert.")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Audio-Dateien werden nach der Verarbeitung automatisch gelöscht.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }

                GroupBox(label: Label("Logging", systemImage: "doc.text")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Vollständiges File-Logging aktivieren", isOn: $fileLoggingEnabled)
                            .onChange(of: fileLoggingEnabled) { _, newValue in
                                if newValue {
                                    Logger.enableFileLogging()
                                } else {
                                    Logger.disableFileLogging()
                                }
                            }

                        Text("Errors und Warnings werden IMMER protokolliert.")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            Button(action: openLogFile) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("Logfile anzeigen")
                                }
                            }
                            .buttonStyle(.bordered)

                            Button(action: openLogDirectory) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("Log-Ordner")
                                }
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }

                        Text("Pfad: \(Logger.currentLogFilePath)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 8)
                }

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Sicherheit", systemImage: "lock")
            }
        }
        .frame(width: 500, height: 400)
    }

    private func openAnthropicConsole() {
        if let url = URL(string: "https://console.anthropic.com/") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkMicrophonePermission() -> Bool {
        return AudioRecorder.isMicrophoneAvailable()
    }

    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    private func openLogFile() {
        let path = Logger.currentLogFilePath
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        } else {
            // Logfile existiert noch nicht, erstelle es
            Logger.info("Logfile manuell geöffnet", category: Logger.general)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if FileManager.default.fileExists(atPath: path) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            }
        }
    }

    private func openLogDirectory() {
        let logDir = Constants.logsDirectory
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(logDir)
    }
}

// MARK: - Sub-Views
struct HotKeyRow: View {
    let mode: String
    let hotkey: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mode)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(hotkey)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .orange)
                .font(.title3)
        }
    }
}

#Preview {
    SettingsWindow(appState: AppState())
}
