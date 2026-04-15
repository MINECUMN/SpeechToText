# SpeechToText — Technical Documentation

## Project Overview

Native macOS menu bar application providing push-to-talk speech-to-text with AI text enhancement.

**Repository:** https://github.com/MINECUMN/SpeechToText
**Bundle ID:** `tech.minec.SpeechToText`
**macOS Requirement:** 13.0 Ventura+
**Xcode Requirement:** 15.0+
**Swift Version:** 5.0+

---

## All Swift Files

| File | Location | Purpose | Lines |
|------|----------|---------|-------|
| `SpeechToTextApp.swift` | App/ | @main entry point, SpeechCoordinator pipeline orchestration | 195 |
| `AppDelegate.swift` | App/ | NSStatusItem menu bar, AppState icon management, settings window | 157 |
| `HotkeyManager.swift` | Core/ | CGEventTap for Ctrl+1/Ctrl+2 push-to-talk detection | 131 |
| `AudioRecorder.swift` | Core/ | AVAudioRecorder M4A 16kHz mono, temp file management | 52 |
| `WhisperService.swift` | Core/ | OpenAI Whisper API multipart upload, transcription | 86 |
| `ClaudeService.swift` | Core/ | Anthropic Claude API, Standard + Social Media modes | 89 |
| `PasteManager.swift` | Core/ | Focus preservation, NSPasteboard, CGEventPost Cmd+V | 41 |
| `SettingsManager.swift` | Settings/ | Singleton, Keychain API keys, UserDefaults, SMAppService | 129 |
| `SettingsView.swift` | Settings/ | SwiftUI settings panel with all configuration options | 205 |

**Total:** 1,085 lines of Swift code across 9 files.

---

## APIs Used

### OpenAI Whisper API

| Setting | Value |
|---------|-------|
| Endpoint | `POST https://api.openai.com/v1/audio/transcriptions` |
| Model | `whisper-1` |
| Auth | `Authorization: Bearer {OPENAI_API_KEY}` |
| Content-Type | `multipart/form-data` |
| Response Format | `text` (plain text) |
| Fields | `model`, `file`, `language` (optional), `response_format` |

### Anthropic Claude API

| Setting | Value |
|---------|-------|
| Endpoint | `POST https://api.anthropic.com/v1/messages` |
| Model | `claude-haiku-4-5-20251001` |
| Max Tokens | 1024 |
| Auth | `x-api-key: {ANTHROPIC_API_KEY}` |
| API Version | `anthropic-version: 2023-06-01` |
| Content-Type | `application/json` |

**Standard Mode System Prompt:** Clean grammar, improve flow, remove filler words, preserve meaning and language.

**Social Media Mode System Prompt:** Same as standard + add exactly N emojis naturally, make engaging.

---

## API Keys

| Key Name | Service | How to obtain |
|----------|---------|---------------|
| OpenAI API Key | OpenAI Whisper API | platform.openai.com/api-keys |
| Anthropic API Key | Claude API | console.anthropic.com |

**Storage:** Both keys are stored in macOS Keychain with separate service identifiers:
- `tech.minec.SpeechToText.openai`
- `tech.minec.SpeechToText.claude`

---

## Permissions Required

| Permission | Framework | Purpose |
|------------|-----------|---------|
| Microphone | AVFoundation | Audio recording |
| Accessibility | ApplicationServices (CGEventTap) | Global hotkey monitoring |
| Notifications | UserNotifications | Error and status notifications |

---

## Info.plist Entries

| Key | Value | Purpose |
|-----|-------|---------|
| `LSUIElement` | `YES` | Menu bar only, no Dock icon |
| `NSMicrophoneUsageDescription` | "SpeechToText needs microphone access to record your voice for transcription." | Microphone permission dialog |
| `NSAppleEventsUsageDescription` | "SpeechToText needs Apple Events access to paste text into other applications." | Apple Events permission |

---

## Entitlements

| Key | Value | Purpose |
|-----|-------|---------|
| `com.apple.security.app-sandbox` | `NO` | Required for CGEventTap (global hotkeys) |
| `com.apple.security.device.audio-input` | `YES` | Microphone access |
| `com.apple.security.hardened-runtime` | `YES` | Security hardening |

---

## Frameworks Used

| Framework | Purpose |
|-----------|---------|
| SwiftUI | Settings panel UI |
| AppKit (Cocoa) | NSStatusItem, NSMenu, NSPasteboard, NSWorkspace |
| AVFoundation | AVAudioRecorder for audio capture |
| Carbon.HIToolbox | Virtual key codes (kVK_ANSI_1, kVK_ANSI_2) |
| Security | Keychain read/write/delete |
| ServiceManagement | SMAppService for launch at login |
| UserNotifications | UNUserNotificationCenter for error notifications |
| ApplicationServices | CGEventTap, CGEventPost for hotkeys and paste simulation |

---

## UserDefaults Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `stt_language` | String | "de" | Whisper language code |
| `stt_emojiCount` | Int | 3 | Emoji count for Social Media mode |
| `stt_launchAtLogin` | Bool | false | Auto-start with macOS |
| `stt_standardHotkey` | String | "Control+1" | Display label |
| `stt_socialMediaHotkey` | String | "Control+2" | Display label |

---

## End-to-End Pipeline Flow

```
1. User holds Control+1 or Control+2
2. HotkeyManager detects keyDown → SpeechCoordinator.didStartRecording(mode:)
3. PasteManager.saveFrontmostApp() captures current app
4. AudioRecorder.startRecording() begins M4A recording
5. Menu bar → red mic icon
6. User releases key → SpeechCoordinator.didStopRecording(mode:)
7. AudioRecorder.stopRecording() returns file URL
8. File size check (< 1KB = silently discard)
9. Menu bar → "..." (Whisper processing)
10. WhisperService.transcribe() → OpenAI API
11. Menu bar → sparkles (Claude processing)
12. ClaudeService.enhance() → Anthropic API
13. PasteManager.pasteText() → re-activate app → NSPasteboard → Cmd+V
14. Menu bar → idle state
15. AudioRecorder.cleanup() removes temp file
```

---

## Error Handling

All errors are displayed via `UserNotifications` (no modal dialogs).

| Error | Notification | Fallback |
|-------|-------------|----------|
| Missing OpenAI Key | "OpenAI API Key fehlt" | Opens Settings |
| Missing Claude Key | "Claude API Key fehlt" | Pastes raw Whisper text |
| Whisper API error | "Transkription fehlgeschlagen: [error]" | — |
| Claude API error | "Textverbesserung fehlgeschlagen" | Pastes raw Whisper text |
| No microphone permission | "Mikrofonzugriff verweigert" | — |
| No accessibility permission | "Bedienungshilfen-Zugriff erforderlich" | — |
| Recording failed | "Aufnahme fehlgeschlagen: [error]" | — |

---

## Build Configuration

| Setting | Value |
|---------|-------|
| Deployment Target | macOS 13.0 |
| Swift Version | 5.0 |
| Bundle Identifier | `tech.minec.SpeechToText` |
| Code Signing | Automatic |
| Hardened Runtime | Enabled |
| App Sandbox | Disabled (required for CGEventTap) |

---

## How to Build and Run

```bash
git clone https://github.com/MINECUMN/SpeechToText.git
cd SpeechToText
open SpeechToText.xcodeproj
# In Xcode: Cmd+R to build and run
```

Or via command line:
```bash
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Debug build
```

---

## How to Export for Another Mac

1. Open project in Xcode
2. Product → Archive
3. Distribute App → Copy App
4. Copy `SpeechToText.app` to target Mac's `/Applications/`
5. On first launch: grant Microphone + Accessibility permissions
6. Open Settings → enter API keys

---

## Known Limitations

- Hotkeys are hardcoded to Control+1 and Control+2
- No audio level visualization during recording
- Not sandboxed (CGEventTap requires it)
- No offline mode (requires internet for both APIs)
- Single pipeline: cannot start new recording while processing
