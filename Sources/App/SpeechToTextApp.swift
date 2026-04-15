import SwiftUI

@main
struct SpeechToTextApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarScene(appState: appState)

        Settings {
            SettingsWindow(appState: appState)
        }
    }
}

// MARK: - MenuBar Scene
struct MenuBarScene: Scene {
    @ObservedRealmModel var appState: AppState
    @State private var statusItem: NSStatusItem?

    var body: some Scene {
        MenuBarExtra("SpeechToText", systemImage: "mic.fill") {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}
