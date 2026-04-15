# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-15

### ✨ Added
- **Complete MVP Implementation** - All 8 phases completed
- Audio recording with AVFoundation
- Speech-to-text transcription with Whisper API
- Intelligent text processing with 4 modes:
  - Direct: 1:1 transcription
  - Polished: Grammatically correct German
  - Rage-to-Polite: Convert angry speech to professional email
  - Social Media: Add emojis to text
- Global hotkeys (⌘⇧1-4) for each mode
- Text insertion via Accessibility API and Clipboard
- macOS Menübar interface
- Settings window with:
  - API key management (Keychain)
  - Hotkey configuration display
  - Permission status checker
  - Security & privacy information
- State management with @Observable
- Secure credential storage in macOS Keychain
- Comprehensive logging with OSLog
- Unit tests for core functionality

### 🔧 Technical Features
- Swift Package Manager support
- SwiftUI for modern macOS UI
- Combine framework for reactive programming
- Async/await for async operations
- Multipart file upload support
- Error handling and recovery
- Audio validation (format, size, duration)
- Cleanup of temporary files

### 📋 Documentation
- Detailed README with setup instructions
- Architecture documentation
- Project structure overview
- Contributing guidelines
- API integration examples

### 🔐 Security
- API keys stored in macOS Keychain (not in code/defaults)
- Temporary audio files cleaned up after transcription
- No sensitive data in logs
- Accessibility permission request on startup

### 🎯 Deployment
- Code signing ready
- Ready for distribution
- DMG creation support
- Proper .gitignore

## [0.1.0] - 2026-04-15

### ✨ Initial Release
- Basic project setup with Swift Package Manager
- SwiftUI Menübar application scaffold
- Initial AppState model
- Settings window framework
- GitHub repository established

---

## Upcoming Features

- [ ] Custom hotkey configuration UI
- [ ] Text editing preview before insertion
- [ ] History of transcriptions
- [ ] Multiple language support (auto-detection)
- [ ] Longer audio handling with chunking
- [ ] Voice profiles (speaker identification)
- [ ] Custom prompt templates
- [ ] Dark mode refinements
- [ ] macOS menu bar enhancements

---

## Known Issues

None at this moment.

## Migration Guide

N/A - Initial release
