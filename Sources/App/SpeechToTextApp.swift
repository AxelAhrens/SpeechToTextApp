import SwiftUI

@main
struct SpeechToTextApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("SpeechToText", systemImage: "mic.fill") {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsWindow(appState: appState)
        }
    }
}
