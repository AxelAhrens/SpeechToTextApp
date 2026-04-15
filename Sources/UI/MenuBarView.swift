import SwiftUI

struct MenuBarView: View {
    @State var appState: AppState
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Title & Status
            HStack {
                Image(systemName: appState.isRecording ? "mic.fill" : "mic")
                    .foregroundColor(appState.isRecording ? .red : .primary)
                    .font(.system(size: 16))

                Text(appState.isRecording ? "Aufnahme läuft..." : "Bereit")
                    .font(.headline)

                Spacer()

                if appState.isRecording {
                    Text(formatDuration(appState.recordingDuration))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // MARK: - Mode Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Modus")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                Picker("Modus", selection: $appState.selectedMode) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(.body)
                            Text(mode.description)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            }

            Divider()

            // MARK: - Recording Button
            HStack(spacing: 12) {
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: appState.isRecording ? "stop.circle.fill" : "record.circle.fill")
                        Text(appState.isRecording ? "Stoppen" : "Aufnahme")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(appState.isRecording ? .red : .blue)

                Button(action: openSettings) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // MARK: - Last Transcription
            if !appState.lastTranscription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Letzte Transkription")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(appState.lastTranscription)
                        .font(.caption)
                        .lineLimit(3)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(4)

                    Button(action: copyLastTranscription) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Kopieren")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // MARK: - Error Alert
            if appState.showError, let error = appState.lastError {
                VStack(spacing: 8) {
                    Label(error.errorDescription ?? "Fehler", systemImage: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)

                    Button("Schließen") {
                        appState.clearError()
                    }
                    .font(.caption)
                }
                .padding(8)
                .background(Color(.systemRed).opacity(0.1))
                .cornerRadius(4)
                .padding(.horizontal)
            }

            Spacer()
                .frame(height: 4)
        }
        .frame(width: 300, alignment: .top)
        .padding(.vertical, 8)
        .onAppear(perform: setupTimer)
        .onDisappear(perform: stopTimer)
    }

    // MARK: - Actions
    private func toggleRecording() {
        if appState.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        appState.isRecording = true
        appState.recordingDuration = 0
        // TODO: Implement actual recording
    }

    private func stopRecording() {
        appState.isRecording = false
        // TODO: Send to API and insert text
    }

    private func openSettings() {
        NSApp.sendAction(#selector(NSApplication.orderFrontStandardAboutPanel(_:)), to: nil, from: nil)
        // Trigger Settings window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: NSApp.delegate, from: nil)
        }
    }

    private func copyLastTranscription() {
        NSPasteboard.general.setString(appState.lastTranscription, forType: .string)
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if appState.isRecording {
                appState.recordingDuration += 0.1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    MenuBarView(appState: AppState())
}
