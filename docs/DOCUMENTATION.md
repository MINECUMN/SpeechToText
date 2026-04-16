# SpeechToText — Technical Documentation

## Project Overview

| Property | Value |
|----------|-------|
| Repository | https://github.com/MINECUMN/SpeechToText |
| Bundle ID | `tech.minec.SpeechToText` |
| macOS Requirement | 13.0 Ventura+ |
| Xcode Requirement | 15.0+ |
| Swift Version | 5.0+ |
| External Dependencies | None |
| Total Lines of Code | ~1,124 (9 Swift files) |

---

## All Swift Files

| File | Location | Purpose | Lines |
|------|----------|---------|-------|
| `SpeechToTextApp.swift` | App/ | @main entry point, `SpeechCoordinator` orchestrates the full pipeline | 214 |
| `AppDelegate.swift` | App/ | `NSStatusItem` menu bar, `AppState` icon management, settings window | 157 |
| `HotkeyManager.swift` | Core/ | `CGEventTap` for Option+S / Option+M push-to-talk | 150 |
| `AudioRecorder.swift` | Core/ | `AVAudioRecorder` M4A 16kHz mono, temp file management | 52 |
| `WhisperService.swift` | Core/ | OpenAI Whisper API multipart upload, transcription | 86 |
| `ClaudeService.swift` | Core/ | Anthropic Claude API, Standard + Social Media modes | 90 |
| `PasteManager.swift` | Core/ | Focus preservation, `NSPasteboard`, `CGEventPost` Cmd+V | 41 |
| `SettingsManager.swift` | Settings/ | Singleton, Keychain API keys, UserDefaults, `SMAppService` | 129 |
| `SettingsView.swift` | Settings/ | SwiftUI settings panel with all config options | 205 |

---

## APIs Used

### OpenAI Whisper API

| Setting | Value |
|---------|-------|
| Endpoint | `POST https://api.openai.com/v1/audio/transcriptions` |
| Model | `whisper-1` |
| Authorization | `Authorization: Bearer {OPENAI_API_KEY}` |
| Content-Type | `multipart/form-data` |
| Form Fields | `model`, `file` (audio), `language` (optional), `response_format` ("text") |
| Audio Format | M4A (AAC), 16kHz, mono |
| Response | Plain text transcription |

### Anthropic Claude API

| Setting | Value |
|---------|-------|
| Endpoint | `POST https://api.anthropic.com/v1/messages` |
| Model | `claude-haiku-4-5-20251001` |
| Max Tokens | 1024 |
| Authorization | `x-api-key: {ANTHROPIC_API_KEY}` |
| Version Header | `anthropic-version: 2023-06-01` |
| Content-Type | `application/json` |

### Claude System Prompts

**Standard Mode (Option+S):**
> You are a text polishing assistant. The user has dictated a message via voice. Your task is to clean up the transcription: fix grammar, improve flow and readability, remove filler words and repetitions. Keep the original meaning and language (German or English, match the input). Keep the same tone and register. Output ONLY the improved text, nothing else.

**Social Media Mode (Option+M):**
> You are a text polishing assistant. The user has dictated a message via voice. Clean up the transcription: fix grammar, improve flow and readability, remove filler words and repetitions. Add exactly [N] emojis placed naturally throughout the text. IMPORTANT: Do NOT add any new content, ideas, sentences or information that the user did not say. Only clean up what was spoken and add emojis. Keep the original meaning, length and language (German or English, match the input). Output ONLY the improved text, nothing else.

---

## API Keys

| Key | Keychain Service ID | How to obtain |
|-----|---------------------|---------------|
| OpenAI API Key | `tech.minec.SpeechToText.openai` | platform.openai.com/api-keys |
| Anthropic API Key | `tech.minec.SpeechToText.claude` | console.anthropic.com |

Both keys are stored in macOS Keychain under account name `apikey`.

---

## Hotkeys

| Hotkey | Mode | Key Code | Modifier |
|--------|------|----------|----------|
| Option+S | Standard | `kVK_ANSI_S` (1) | `.maskAlternate` (Option) |
| Option+M | Social Media | `kVK_ANSI_M` (46) | `.maskAlternate` (Option) |

**Detection:** `CGEventTap` at `cgSessionEventTap` with `headInsertEventTap` placement. Events are swallowed (return `nil`) to prevent characters from reaching the active app.

**Modifier filtering:** Only Option key accepted. Command and Control modifiers are explicitly rejected to avoid conflicts.

**Release detection:** Key up event stops recording. Option key release (via `flagsChanged`) also stops recording as a safety fallback.

---

## Permissions

### Runtime Permissions

| Permission | Framework | Purpose | How granted |
|------------|-----------|---------|-------------|
| Microphone | AVFoundation | Audio recording | System dialog on first use |
| Accessibility | ApplicationServices | CGEventTap global hotkeys | Manual in System Settings |
| Notifications | UserNotifications | Error/status messages | Requested at app launch |

### Accessibility Permission Details

The app calls `AXIsProcessTrustedWithOptions` with prompt option at startup. If not trusted, it shows a system dialog.

**During Xcode development:** The built binary in DerivedData must be added to Accessibility. The permission resets after each rebuild (code signature changes).

**With exported .app:** Permission persists across launches.

### Info.plist Entries

| Key | Value | Purpose |
|-----|-------|---------|
| `LSUIElement` | `YES` | Menu bar only, no Dock icon |
| `NSMicrophoneUsageDescription` | "SpeechToText needs microphone access to record your voice for transcription." | Microphone permission dialog |
| `NSAppleEventsUsageDescription` | "SpeechToText needs Apple Events access to paste text into other applications." | Apple Events permission |

### Entitlements

| Key | Value | Reason |
|-----|-------|--------|
| `com.apple.security.app-sandbox` | `NO` | CGEventTap cannot work in sandbox |
| `com.apple.security.device.audio-input` | `YES` | Microphone recording |
| `com.apple.security.hardened-runtime` | `YES` | Security hardening |

---

## Apple Frameworks Used

| Framework | Import | Purpose |
|-----------|--------|---------|
| SwiftUI | `import SwiftUI` | Settings panel UI |
| AppKit | `import Cocoa` | NSStatusItem, NSMenu, NSPasteboard, NSWorkspace, NSWindow |
| AVFoundation | `import AVFoundation` | AVAudioRecorder |
| Carbon | `import Carbon.HIToolbox` | Virtual key codes (kVK_ANSI_S, kVK_ANSI_M) |
| Security | `import Security` | Keychain (SecItemAdd, SecItemCopyMatching, SecItemDelete) |
| ServiceManagement | `import ServiceManagement` | SMAppService for launch at login |
| UserNotifications | `import UserNotifications` | UNUserNotificationCenter |
| ApplicationServices | (implicit via Cocoa) | CGEventTap, CGEventPost, AXIsProcessTrusted |
| Foundation | `import Foundation` | URLSession, JSONSerialization, FileManager |

---

## UserDefaults Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `stt_language` | String | `"de"` | Whisper language code |
| `stt_emojiCount` | Int | `3` | Emoji count for Social Media mode |
| `stt_launchAtLogin` | Bool | `false` | Auto-start with macOS |
| `stt_standardHotkey` | String | `"Option+S"` | Display label |
| `stt_socialMediaHotkey` | String | `"Option+M"` | Display label |

---

## End-to-End Pipeline

```
1.  User holds Option+S or Option+M
2.  HotkeyManager detects keyDown with maskAlternate flag
3.  SpeechCoordinator.didStartRecording(mode:) called
4.  PasteManager.saveFrontmostApp() captures active app
5.  AudioRecorder.startRecording() begins M4A recording
6.  AppDelegate.updateState(.recording) → red mic icon
7.  User releases key
8.  HotkeyManager detects keyUp → SpeechCoordinator.didStopRecording
9.  AudioRecorder.stopRecording() returns temp file URL
10. File size check: < 1KB → silently discard (accidental tap)
11. AppDelegate.updateState(.processingWhisper) → "..." icon
12. WhisperService.transcribe() sends audio to OpenAI API
13. AppDelegate.updateState(.processingClaude) → sparkles icon
14. ClaudeService.enhance() sends text to Anthropic API
15. PasteManager.pasteText() → re-activate saved app → Cmd+V
16. AppDelegate.updateState(.idle) → normal mic icon
17. AudioRecorder.cleanup() removes temp file
```

---

## Error Handling

All errors displayed via `UNUserNotificationCenter` — no modal dialogs.

| Error | Notification Title | Fallback Action |
|-------|--------------------|----------------|
| Missing OpenAI Key | "OpenAI API Key fehlt" | Opens Settings |
| Missing Claude Key | "Claude API Key fehlt" | Pastes raw Whisper text |
| Whisper API error | "Transkription fehlgeschlagen: [error]" | Nothing pasted |
| Claude API error | "Textverbesserung fehlgeschlagen" | Pastes raw Whisper text |
| No microphone | "Mikrofonzugriff verweigert" | — |
| No accessibility | "Bedienungshilfen-Zugriff erforderlich" | Retries after 5 seconds |
| Recording failed | "Aufnahme fehlgeschlagen: [error]" | Returns to idle |

### Edge Cases

| Case | Handling |
|------|---------|
| Very short recording (< 1KB) | Silently discarded |
| Concurrent hotkey press during processing | Blocked by `isProcessing` flag |
| Option key released without S/M | No action |
| Event tap timeout | Auto re-enabled |
| App termination | Coordinator cleanup in `applicationWillTerminate` |

---

## Build Configuration

| Setting | Value |
|---------|-------|
| Deployment Target | macOS 13.0 |
| Swift Version | 5.0 |
| Bundle Identifier | `tech.minec.SpeechToText` |
| Code Signing | Automatic |
| Hardened Runtime | Enabled |
| App Sandbox | Disabled |

### Build Commands

```bash
# Debug build
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Debug build

# Release build
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Release build

# Open in Xcode
open SpeechToText.xcodeproj
```

---

## Export for Another Mac

1. Open project in Xcode
2. Product → Archive
3. Distribute App → Copy App
4. Copy `SpeechToText.app` to target Mac's `/Applications/`
5. On first launch: grant Microphone + Accessibility permissions
6. Open Settings via menu bar icon → enter API keys

---

## Known Limitations

| Limitation | Details |
|------------|---------|
| Fixed hotkeys | Option+S and Option+M are not remappable at runtime |
| No audio visualization | No level meter during recording |
| Not sandboxed | CGEventTap requires non-sandboxed app |
| Internet required | Both Whisper and Claude APIs are cloud-based |
| Sequential pipeline | Cannot start new recording while processing |
| Dev permission reset | Accessibility resets after each Xcode rebuild |

---

## Git History

| Commit | Description |
|--------|-------------|
| STEP 0 | GitHub repo created, initial structure |
| STEP 1 | Xcode project structure, all folders, targets, entitlements |
| STEP 2 | HotkeyManager — CGEventTap with push-to-talk |
| STEP 3 | AudioRecorder — AVAudioRecorder M4A 16kHz mono |
| STEP 4 | WhisperService — OpenAI Whisper API multipart upload |
| STEP 5 | ClaudeService — Anthropic API with both modes |
| STEP 6 | PasteManager — focus preservation + Cmd+V |
| STEP 7 | SettingsManager — Keychain + UserDefaults + SMAppService |
| STEP 8 | SettingsView — SwiftUI settings panel |
| STEP 9 | Menu Bar UI — NSStatusItem with 5 icon states |
| STEP 10 | Full integration — end-to-end pipeline |
| STEP 11 | Error handling — concurrent guard, notifications |
| STEP 12 | Final documentation review |
| Fix | Swallow hotkey events, Accessibility docs for Xcode |
| Fix | Hotkeys changed to Option+S / Option+M, AXIsProcessTrustedWithOptions |
| Fix | Social Media prompt — only cleanup + emojis, no extra content |
