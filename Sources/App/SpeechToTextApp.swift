import SwiftUI
import Combine

@main
struct SpeechToTextApp: App {
    @State private var appState = AppState()
    @State private var hotkeyManager = GlobalHotkeyManager.shared
    @State private var transcriptionService = TranscriptionService()
    @State private var subscriptions = Set<AnyCancellable>()

    init() {
        Logger.logAppStart()
    }

    var body: some Scene {
        MenuBarExtra("SpeechToText", systemImage: "mic.fill") {
            MenuBarView(appState: appState, transcriptionService: transcriptionService)
                .onAppear {
                    setupHotkeys()
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsWindow(appState: appState)
        }
    }

    private func setupHotkeys() {
        hotkeyManager.behavior = appState.hotkeyBehavior
        hotkeyManager.register()

        hotkeyManager.startRecording
            .receive(on: DispatchQueue.main)
            .sink { mode in
                appState.selectedMode = mode
                transcriptionService.startTranscription(mode: mode, apiKey: appState.apiKey)
            }
            .store(in: &subscriptions)

        hotkeyManager.stopRecording
            .receive(on: DispatchQueue.main)
            .sink { mode in
                Task {
                    await transcriptionService.stopTranscriptionAndProcess(
                        mode: mode,
                        apiKey: appState.apiKey
                    )
                }
            }
            .store(in: &subscriptions)
    }
}
