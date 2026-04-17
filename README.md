# SpeechToText

A native macOS menu bar application providing push-to-talk speech-to-text with AI-powered text enhancement.

## How It Works

Hold a hotkey, speak, release — your enhanced text gets pasted into the active application.

```
Hold Option+S, Option+M or Option+E → Speak → Release → Text appears in your active app
```

| Hotkey | Mode | What it does |
|--------|------|-------------|
| **Option+S** (hold) | Standard | Fixes grammar, removes filler words, improves readability |
| **Option+M** (hold) | Social Media | Minimal cleanup + adds emojis naturally (no extra content added) |
| **Option+E** (hold) | Email | Formats as professional email with greeting, body, closing sentence (no signature) |

## Requirements

- **macOS 13 Ventura** or newer
- **Xcode 15+** (to build from source)
- **OpenAI API Key** — for Whisper speech-to-text
- **Anthropic API Key** — for Claude text enhancement

## Setup from Scratch

### 1. Clone and open

```bash
git clone https://github.com/MINECUMN/SpeechToText.git
cd SpeechToText
open SpeechToText.xcodeproj
```

### 2. Build and run

Press **Cmd+R** in Xcode.

### 3. Grant permissions

**Microphone:** Allow when the system dialog appears.

**Accessibility (required for global hotkeys):**
- System Settings → Privacy & Security → Accessibility
- When running from **Xcode**: add the built app from DerivedData:
  1. Click "+"
  2. Press Cmd+Shift+G
  3. Paste: `~/Library/Developer/Xcode/DerivedData/` → find the `SpeechToText-…/Build/Products/Debug/SpeechToText.app`
  4. Enable the toggle
- When running the **exported .app**: add `SpeechToText.app` directly

> **Note:** During development, the Accessibility permission resets after each rebuild. You need to re-add the app each time. This does not happen with exported/archived builds.

### 4. Configure API keys

1. Click the microphone icon in the menu bar → **Settings...**
2. Enter your **OpenAI API Key** → Save
3. Enter your **Anthropic API Key** → Save

Both keys are stored securely in the macOS Keychain.

### 5. Test it

1. Open any app with a text field (Terminal, Notes, TextEdit, browser...)
2. Click into the text field
3. Hold **Option+S**, speak a sentence, release
4. The enhanced text appears automatically

## Export as Standalone App (without Xcode)

Build and install the app so it runs independently — no Xcode needed:

```bash
cd /path/to/SpeechToText

# 1. Archive Release build
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText \
  -configuration Release -archivePath ~/Desktop/SpeechToText.xcarchive archive

# 2. Extract .app from archive
cp -R ~/Desktop/SpeechToText.xcarchive/Products/Applications/SpeechToText.app \
  ~/Desktop/SpeechToText.app

# 3. Install to Applications
cp -R ~/Desktop/SpeechToText.app /Applications/SpeechToText.app

# 4. Cleanup
rm -rf ~/Desktop/SpeechToText.xcarchive ~/Desktop/SpeechToText.app

# 5. Launch
open /Applications/SpeechToText.app
```

After launch:
- Add `/Applications/SpeechToText.app` to **System Settings → Privacy & Security → Accessibility**
- The Accessibility permission persists permanently for exported builds (unlike Xcode debug builds)

### Enable Autostart

In the app: Menu bar icon → Settings → **Launch at Login** toggle.

Or via command line:
```bash
defaults write tech.minec.SpeechToText stt_launchAtLogin -bool true
```

## Installing on Another Mac

1. Copy `/Applications/SpeechToText.app` to the other Mac's Applications folder
2. On first launch: grant Microphone and Accessibility permissions
3. Open Settings (menu bar icon) and enter API keys
4. Enable "Launch at Login" if desired

## Where to Get API Keys

| Key | URL | Cost |
|-----|-----|------|
| OpenAI API Key | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | ~$0.006/minute |
| Anthropic API Key | [console.anthropic.com](https://console.anthropic.com) | ~$0.001/request |

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| Platform | macOS 13 Ventura+ |
| UI | SwiftUI + AppKit (NSStatusItem) |
| Speech-to-Text | OpenAI Whisper API (`whisper-1`) |
| Text Enhancement | Anthropic Claude API (`claude-haiku-4-5-20251001`) |
| Key Storage | macOS Keychain |
| Preferences | UserDefaults |
| Dependencies | None — pure Apple frameworks + URLSession |

## Architecture

```
SpeechToText/
├── App/
│   ├── SpeechToTextApp.swift      # @main entry, SpeechCoordinator (pipeline)
│   └── AppDelegate.swift          # Menu bar UI, icon states, settings window
├── Core/
│   ├── HotkeyManager.swift        # CGEventTap — Option+S / Option+M / Option+E
│   ├── AudioRecorder.swift        # AVAudioRecorder — M4A 16kHz mono
│   ├── WhisperService.swift       # OpenAI Whisper API — multipart upload
│   ├── ClaudeService.swift        # Claude API — Standard + Social Media + Email
│   └── PasteManager.swift         # Focus save → clipboard → Cmd+V paste
├── Settings/
│   ├── SettingsManager.swift      # Keychain + UserDefaults singleton
│   └── SettingsView.swift         # SwiftUI settings panel
├── Assets.xcassets/
├── Info.plist
└── SpeechToText.entitlements
```

### Pipeline Flow

```
Option+S/M/E held → HotkeyManager detects
  → PasteManager saves frontmost app
  → AudioRecorder starts recording
  → Key released
  → WhisperService transcribes (OpenAI API)
  → ClaudeService enhances text (Anthropic API)
  → PasteManager re-activates app + pastes via Cmd+V
```

## Menu Bar Icon States

| State | Icon | Meaning |
|-------|------|---------|
| Idle (Standard) | 🎤 | Ready — Option+S to record |
| Idle (Social Media) | 🎤📱 | Ready — Option+M to record |
| Idle (Email) | 🎤✉️ | Ready — Option+E to record |
| Recording | 🔴 | Recording in progress |
| Transcribing | ⋯ | Whisper API processing |
| Enhancing | ✨ | Claude API processing |

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| OpenAI API Key | — | Stored in macOS Keychain |
| Claude API Key | — | Stored in macOS Keychain |
| Language | Deutsch | Auto-Detect / Deutsch / English |
| Emoji Count | 3 | 1–20, only used in Social Media Mode |
| Launch at Login | Off | Auto-start with macOS |

## Error Handling

All errors are shown as macOS notifications — no modal dialogs.

| Error | What happens |
|-------|-------------|
| Missing OpenAI Key | Notification + Settings opens |
| Missing Claude Key | Notification + raw Whisper text is pasted |
| Whisper API error | Notification with error details |
| Claude API error | Notification + raw Whisper text is pasted as fallback |
| No microphone access | System dialog triggered |
| No accessibility access | System dialog triggered + notification |

## Known Limitations

- Hotkeys (Option+S / Option+M / Option+E) are not remappable at runtime
- No audio level visualization during recording
- App is not sandboxed (required for CGEventTap global hotkeys)
- Requires internet (both APIs are cloud-based)
- Cannot start a new recording while processing is in progress
- Accessibility permission resets after each Xcode rebuild (not an issue with exported .app)

## License

MIT License — see [LICENSE](LICENSE)

## Repository

https://github.com/MINECUMN/SpeechToText
