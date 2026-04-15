# 🎙️ SpeechToTextApp

Native macOS Menübar Speech-to-Text App mit intelligenten Text-Umschreib-Modi, powered by Claude API.

## Features

✨ **Kernfunktionen:**
- 🎤 Globale Sprachaufnahme via Menüleiste
- 🤖 Automatische Transkription mit Whisper API
- ✍️ Intelligente Text-Verarbeitung mit Claude AI
- 📝 4 verschiedene Schreib-Modi
- ⌨️ Globale Hotkeys (⌘⇧1-4)
- 🔐 Sichere API-Key-Verwaltung (Keychain)

### Modi

| Modus | Hotkey | Funktion |
|-------|--------|----------|
| **Direkt** | ⌘⇧1 | 1:1 Transkription (roher Text) |
| **Polished** | ⌘⇧2 | Flüssiges Schriftsdeutsch, grammatikalisch korrekt |
| **Wut → Höflich** | ⌘⇧3 | Wandelt wütende Rede in professionelle Email um |
| **Social Media** | ⌘⇧4 | Transkription mit passenden Emojis |

## Requirements

- macOS 13.0+
- Swift 5.9+
- Anthropic API Key (Claude)
- Microphone

## Installation

### 1. Clone Repository
```bash
git clone https://github.com/AxelAhrens/SpeechToTextApp.git
cd SpeechToTextApp
```

### 2. API Key Setup
1. Hole einen Anthropic API Key von [console.anthropic.com](https://console.anthropic.com)
2. Öffne die App und gehe zu Settings → API
3. Füge deinen API Key ein (wird sicher im Keychain gespeichert)

### 3. Build & Run
```bash
# Mit Swift Package Manager
swift build
swift run SpeechToTextApp

# Oder in Xcode
open Package.swift
```

### 4. Berechtigungen
Die App wird folgende Berechtigungen anfordern:
- **Microphone** – Für Sprachaufnahme
- **Accessibility** – Um Text in andere Apps einzufügen

> ℹ️ Diese Berechtigungen sind notwendig für die Kernfunktionalität!

## Nutzung

### Schritt 1: API Key eingeben
Settings → API → Anthropic API Key eingeben

### Schritt 2: Hotkey nutzen
Drücke einen der globalen Hotkeys:
- `⌘⇧1` – Direkt Transkribieren
- `⌘⇧2` – Poliertes Deutsch
- `⌘⇧3` – Wut in Email umwandeln
- `⌘⇧4` – Mit Emojis

### Schritt 3: Sprechen
Nach Hotkey-Druck: Sprechen → Text wird transkribiert + verarbeitet → Automatisch eingefügt

## Projekt-Struktur

```
SpeechToTextApp/
├── Sources/
│   ├── App/
│   │   └── SpeechToTextApp.swift        # Main Entry Point
│   ├── Models/
│   │   └── AppState.swift              # State Management
│   ├── UI/
│   │   ├── MenuBarView.swift           # Menüleisten-UI
│   │   └── SettingsWindow.swift        # Preferences
│   ├── Audio/                          # (Phase 2)
│   │   ├── AudioRecorder.swift
│   │   └── AudioProcessor.swift
│   ├── API/                            # (Phase 3)
│   │   ├── APIClient.swift
│   │   ├── WhisperAPI.swift
│   │   └── ClaudeAPI.swift
│   ├── Services/                       # (Phase 4+)
│   │   ├── TranscriptionService.swift
│   │   ├── AccessibilityService.swift
│   │   └── GlobalHotkeyManager.swift
│   └── Utils/
│       ├── Constants.swift             # Konfiguration
│       └── Logger.swift                # Logging
├── Package.swift
├── .gitignore
└── README.md
```

## Entwicklung

### Phase 1: ✅ Basis UI & State
- Menüleisten-App
- Settings Window
- AppState mit Keychain

### Phase 2: 🔄 Audio-Aufnahme
- AVFoundation Integration
- Mikrofon-Recording

### Phase 3: 🔄 API-Integration
- Whisper API (Speech-to-Text)
- Claude API (Text-Modi)

### Phase 4: 🔄 Text-Einfügung
- Accessibility API
- Keyboard Events

### Phase 5: 🔄 Globale Hotkeys
- Hotkey-Manager
- Mode-Implementierung

### Phase 6: 🔄 Settings & Persistierung
- UserDefaults
- Hotkey-Customization

### Phase 7: 🔄 Testing & Fehlerbehandlung
- Unit Tests
- Error Handling

### Phase 8: 🔄 Deployment
- Code Signing
- Release Build

## API-Integration

### Anthropic Claude API

**Text-Umschreibung:**
```swift
POST https://api.anthropic.com/v1/messages
Body: {
  "model": "claude-3-5-sonnet-20241022",
  "messages": [{
    "role": "user",
    "content": "[Modus-Prompt]\n\nText: {transkription}"
  }]
}
```

**Modus-Prompts:**
- **Polished:** Grammatikalische Verbesserung
- **Rage-to-Polite:** Wut → Professionelle Email
- **Social Media:** Text mit Emojis

### OpenAI Whisper API

**Speech-to-Text:**
```swift
POST https://api.openai.com/v1/audio/transcriptions
Body: {
  "file": audio_file,
  "model": "whisper-1",
  "language": "de"
}
```

## Sicherheit

🔐 **API Keys:**
- Werden im macOS Keychain gespeichert (nicht im Code!)
- Nicht in Logs protokolliert
- Lokal nur im RAM während der Nutzung

🔒 **Audio:**
- Wird nach Transkription sofort gelöscht
- Nicht persistent gespeichert

## Lizenz

MIT License – siehe LICENSE Datei

## Author

Axel Ahrens – [GitHub](https://github.com/AxelAhrens)

## Contributing

Contributions willkommen! Bitte:
1. Fork das Repo
2. Feature Branch erstellen (`git checkout -b feature/AmazingFeature`)
3. Commits (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Pull Request öffnen

## Support

Hast du Fragen oder Probleme?
- Issues: [GitHub Issues](https://github.com/AxelAhrens/SpeechToTextApp/issues)
- Diskussion: [GitHub Discussions](https://github.com/AxelAhrens/SpeechToTextApp/discussions)

---

**Status:** 🚀 In aktiver Entwicklung (Phase 1 abgeschlossen)
