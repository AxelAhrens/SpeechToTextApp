import SwiftUI
import Combine

struct MenuBarView: View {
    @State var appState: AppState
    @State private var transcriptionService: TranscriptionService?
    @State private var hotkeyMonitor: HotkeyMonitor?
    @State private var subscriptions = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if let service = transcriptionService, service.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: (transcriptionService?.isRecording ?? false) ? "mic.fill" : "mic")
                        .foregroundColor((transcriptionService?.isRecording ?? false) ? .red : .primary)
                        .font(.system(size: 16))
                }

                Text((transcriptionService?.isProcessing ?? false) ? "Verarbeitet..." :
                     (transcriptionService?.isRecording ?? false) ? "Aufnahme läuft..." : "Bereit")
                    .font(.headline)

                Spacer()

                if let service = transcriptionService, service.isRecording {
                    Text(formatDuration(service.recordingDuration))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

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

            HStack(spacing: 12) {
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: (transcriptionService?.isRecording ?? false) ? "stop.circle.fill" : "record.circle.fill")
                        Text((transcriptionService?.isRecording ?? false) ? "Stoppen" : "Aufnahme")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint((transcriptionService?.isRecording ?? false) ? .red : .blue)
                .disabled(transcriptionService?.isProcessing ?? false)

                Button(action: openSettings) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if let service = transcriptionService, !service.lastProcessedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Letztes Ergebnis")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(service.lastProcessedText)
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

            if let service = transcriptionService, let error = service.error {
                VStack(spacing: 8) {
                    Label(error.errorDescription ?? "Fehler", systemImage: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)

                    Button("Schließen") {
                        service.error = nil
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
        .onAppear(perform: setupServices)
        .onDisappear(perform: cleanupServices)
    }

    private func toggleRecording() {
        guard let service = transcriptionService else { return }
        if service.isRecording {
            Task {
                await service.stopTranscriptionAndProcess(
                    mode: appState.selectedMode,
                    apiKey: appState.apiKey
                )
            }
        } else {
            service.startTranscription(mode: appState.selectedMode, apiKey: appState.apiKey)
        }
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: NSApp.delegate, from: nil)
    }

    private func copyLastText() {
        guard let service = transcriptionService else { return }
        ClipboardService.shared.copyText(service.lastProcessedText)
    }

    private func insertLastText() {
        guard let service = transcriptionService else { return }
        Task {
            try? AccessibilityService.shared.insertText(service.lastProcessedText)
        }
    }

    private func setupServices() {
        transcriptionService = TranscriptionService()
        hotkeyMonitor = HotkeyMonitor()
        hotkeyMonitor?.startMonitoring()
        hotkeyMonitor?.hotkeyTriggered.sink { mode in
            appState.selectedMode = mode
            toggleRecording()
        }.store(in: &subscriptions)
    }

    private func cleanupServices() {
        hotkeyMonitor?.stopMonitoring()
        subscriptions.removeAll()
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
