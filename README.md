# SpeechToText

A native macOS menu bar application providing push-to-talk speech-to-text with AI-powered text enhancement.

## Overview

Hold a hotkey, speak, release — your enhanced text gets pasted into the active application.

- **Control+1**: Standard Mode — cleans up grammar, flow, filler words
- **Control+2**: Social Media Mode — polishes text and adds configurable emojis

## How It Works

```
Hold Ctrl+1/2 → Record audio → Release key → Whisper transcription → Claude enhancement → Auto-paste
```

1. Hold **Control+1** (Standard) or **Control+2** (Social Media)
2. Speak your message
3. Release the key
4. The app transcribes via OpenAI Whisper, enhances via Claude, and pastes the result into your active text field

## Requirements

- **macOS 13 Ventura** or newer
- **Xcode 15+** (to build from source)
- **OpenAI API Key** (for Whisper transcription)
- **Anthropic API Key** (for Claude text enhancement)

## Setup from Scratch

1. Clone the repository:
   ```bash
   git clone https://github.com/MINECUMN/SpeechToText.git
   ```

2. Open the project in Xcode:
   ```bash
   cd SpeechToText
   open SpeechToText.xcodeproj
   ```

3. Build and run (**Cmd+R**)

4. Grant permissions when prompted:
   - **Microphone**: Required for recording
   - **Accessibility**: Required for global hotkeys (System Settings → Privacy & Security → Accessibility)

5. Configure API keys:
   - Click the microphone icon in the menu bar → **Settings...**
   - Enter your OpenAI API Key
   - Enter your Anthropic (Claude) API Key
   - Both keys are stored securely in the macOS Keychain

## Installing on Another Mac

1. In Xcode: **Product → Archive → Distribute App → Copy App**
2. Copy the exported `SpeechToText.app` to the other Mac's Applications folder
3. On first launch: grant Microphone and Accessibility permissions
4. Open Settings and enter API keys

## API Keys Required

| Key | Where to get it | Purpose |
|-----|-----------------|---------|
| OpenAI API Key | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | Whisper speech-to-text |
| Anthropic API Key | [console.anthropic.com](https://console.anthropic.com) | Claude text enhancement |

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| Platform | macOS 13 Ventura+ |
| UI Framework | SwiftUI + AppKit (NSStatusItem) |
| Speech-to-Text | OpenAI Whisper API (`whisper-1`) |
| Text Enhancement | Anthropic Claude API (`claude-haiku-4-5-20251001`) |
| Key Storage | macOS Keychain |
| Preferences | UserDefaults |
| Dependencies | None — pure Apple frameworks + URLSession |

## Architecture

```
SpeechToText/
├── App/
│   ├── SpeechToTextApp.swift     # @main entry, SpeechCoordinator (pipeline orchestration)
│   └── AppDelegate.swift         # Menu bar UI, icon states, settings window
├── Core/
│   ├── HotkeyManager.swift       # CGEventTap for Ctrl+1/Ctrl+2 push-to-talk
│   ├── AudioRecorder.swift       # AVAudioRecorder, M4A 16kHz mono
│   ├── WhisperService.swift      # OpenAI Whisper API (multipart upload)
│   ├── ClaudeService.swift       # Anthropic Claude API (Standard + Social Media modes)
│   └── PasteManager.swift        # Focus preservation + NSPasteboard + Cmd+V simulation
├── Settings/
│   ├── SettingsManager.swift     # Keychain API keys + UserDefaults preferences
│   └── SettingsView.swift        # SwiftUI settings panel
├── Assets.xcassets/
├── Info.plist
└── SpeechToText.entitlements
```

## Menu Bar States

| State | Icon | Description |
|-------|------|-------------|
| Idle (Standard) | Microphone | Ready, Standard Mode active |
| Idle (Social Media) | Microphone + phone emoji | Ready, Social Media Mode active |
| Recording | Red microphone | Recording in progress |
| Transcribing | Ellipsis circle + "..." | Whisper API processing |
| Enhancing | Sparkles | Claude API processing |

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| OpenAI API Key | — | Stored in Keychain |
| Claude API Key | — | Stored in Keychain |
| Language | Deutsch | Auto / Deutsch / English |
| Emoji Count | 3 | 1–20, for Social Media Mode |
| Launch at Login | Off | Auto-start with macOS |

## Known Limitations

- Hotkeys are hardcoded to Control+1 and Control+2 (display is configurable, key codes are not yet remappable at runtime)
- No audio level indicator during recording
- Requires Accessibility permission for global hotkey monitoring
- App is not sandboxed (required for CGEventTap)

## License

MIT License — see [LICENSE](LICENSE)

## Repository

https://github.com/MINECUMN/SpeechToText
