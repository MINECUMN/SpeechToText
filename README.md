# SpeechToText

A native macOS menu bar application providing push-to-talk speech-to-text with AI-powered text enhancement.

## Overview

Hold a hotkey, speak, release — your enhanced text gets pasted into the active application.

- **Control+1**: Standard Mode — cleans up grammar, flow, filler words
- **Control+2**: Social Media Mode — polishes text and adds emojis

## Current Status

- [x] Step 0: GitHub repository created, initial structure committed
- [x] Step 1: Xcode project structure (builds successfully)
- [x] Step 2: HotkeyManager (global hotkeys via CGEventTap)
- [x] Step 3: AudioRecorder (AVAudioRecorder, m4a 16kHz mono)
- [x] Step 4: WhisperService (OpenAI Whisper API)
- [x] Step 5: ClaudeService (Anthropic Claude API, both modes)
- [x] Step 6: PasteManager (focus preservation + CGEventPost Cmd+V)
- [x] Step 7: SettingsManager (Keychain + UserDefaults + Launch at Login)
- [x] Step 8: SettingsView (SwiftUI settings panel)
- [x] Step 9: Menu Bar UI (NSStatusItem, icon states, dropdown menu)
- [x] Step 10: Full integration (end-to-end flow working)
- [ ] Step 11: Error handling
- [ ] Step 12: Final documentation review

## Tech Stack

- **Language:** Swift 5.9+
- **Platform:** macOS 13 Ventura+
- **Speech-to-Text:** OpenAI Whisper API
- **Text Enhancement:** Anthropic Claude API (claude-haiku-4-5-20251001)
- **Dependencies:** None (pure Apple frameworks + URLSession)

## API Keys Required

| Key | Purpose |
|-----|---------|
| OpenAI API Key | Whisper speech-to-text transcription |
| Anthropic API Key | Claude text enhancement |

Keys are stored securely in the macOS Keychain. Configure them in the app's Settings panel.

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/MINECUMN/SpeechToText.git
   ```
2. Open `SpeechToText.xcodeproj` in Xcode 15+
3. Build and run (Cmd+R)
4. Click the menu bar icon → Settings → Enter your API keys
5. Grant Accessibility and Microphone permissions when prompted

## Architecture

```
SpeechToText/
├── App/              # App entry point + AppDelegate
├── Core/             # HotkeyManager, AudioRecorder, WhisperService, ClaudeService, PasteManager
├── Settings/         # SettingsManager + SwiftUI SettingsView
└── Assets.xcassets/  # App icons and assets
```

## License

MIT License — see [LICENSE](LICENSE)
