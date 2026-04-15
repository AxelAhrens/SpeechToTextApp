import SwiftUI
import Combine

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettingsAction
    @State var appState: AppState
    var transcriptionService: TranscriptionService

    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Header
            HStack {
                if transcriptionService.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: transcriptionService.isRecording ? "mic.fill" : "mic")
                        .foregroundColor(transcriptionService.isRecording ? .red : .primary)
                        .font(.system(size: 16))
                }

                Text(transcriptionService.isProcessing ? "Verarbeitet..." :
                     transcriptionService.isRecording ? "Aufnahme läuft..." : "Bereit")
                    .font(.headline)

                Spacer()

                if transcriptionService.isRecording {
                    Text(formatDuration(transcriptionService.recordingDuration))
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
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            }

            Divider()

            // MARK: - Record Button + Settings
            HStack(spacing: 12) {
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: transcriptionService.isRecording ? "stop.circle.fill" : "record.circle.fill")
                        Text(transcriptionService.isRecording ? "Stoppen" : "Aufnahme")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(transcriptionService.isRecording ? .red : .blue)
                .disabled(transcriptionService.isProcessing)

                Button(action: { openSettingsAction() }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // MARK: - Hotkey Hint
            HStack {
                Image(systemName: "keyboard")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("⌘⇧1-4 für Schnellstart (\(appState.hotkeyBehavior.displayName))")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)

            // MARK: - Last Result
            if !transcriptionService.lastProcessedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Letztes Ergebnis")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(transcriptionService.lastProcessedText)
                        .font(.caption)
                        .lineLimit(3)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(4)

                    HStack(spacing: 8) {
                        Button(action: copyLastText) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Kopieren")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Button(action: insertLastText) {
                            HStack {
                                Image(systemName: "arrow.right.doc")
                                Text("Einfügen")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // MARK: - Error
            if let error = transcriptionService.error {
                VStack(spacing: 8) {
                    Label(error.errorDescription ?? "Fehler", systemImage: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)

                    Button("Schließen") {
                        transcriptionService.error = nil
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
        .frame(width: 320, alignment: .top)
        .padding(.vertical, 8)
    }

    // MARK: - Actions
    private func toggleRecording() {
        if transcriptionService.isRecording {
            Task {
                await transcriptionService.stopTranscriptionAndProcess(
                    mode: appState.selectedMode,
                    apiKey: appState.apiKey
                )
            }
        } else {
            transcriptionService.startTranscription(mode: appState.selectedMode, apiKey: appState.apiKey)
        }
    }

    private func copyLastText() {
        ClipboardService.shared.copyText(transcriptionService.lastProcessedText)
    }

    private func insertLastText() {
        Task {
            try? AccessibilityService.shared.insertText(transcriptionService.lastProcessedText)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
