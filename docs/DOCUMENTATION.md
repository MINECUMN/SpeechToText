# SpeechToText — Technical Documentation

## Step 0: GitHub Repository Setup

### What was implemented
- Created public GitHub repository at https://github.com/MINECUMN/SpeechToText
- Initialized with README.md, .gitignore (Swift/Xcode), MIT LICENSE
- Created `docs/` folder for documentation

### Repository Structure
```
SpeechToText/
├── .gitignore          # Swift/Xcode/macOS ignores
├── LICENSE             # MIT License
├── README.md           # Project overview and status
└── docs/
    ├── DOCUMENTATION.md    # This file — technical details
    └── DOCUMENTATION.html  # HTML version of this documentation
```

### Configuration
- Git user: MINECUMN
- Git email: michael.netzig@minec.tech
- Remote: https://github.com/MINECUMN/SpeechToText.git

### Dependencies
None yet — project structure only.

### API Keys Required
| Key | Service | Purpose |
|-----|---------|---------|
| OpenAI API Key | OpenAI Whisper API | Speech-to-text transcription |
| Anthropic API Key | Claude API | AI text enhancement |

---

## Step 1: Xcode Project Structure

### What was implemented
- Complete Xcode project (`SpeechToText.xcodeproj`) with proper build settings
- All source file placeholders in correct folder structure
- Info.plist with LSUIElement (menu bar only), microphone and Apple Events usage descriptions
- Entitlements file with audio input and hardened runtime
- Asset catalog with AppIcon placeholder
- Bundle identifier: `tech.minec.SpeechToText`
- Deployment target: macOS 13.0

### Project Structure
```
SpeechToText/
├── SpeechToText.xcodeproj/
│   └── project.pbxproj
└── SpeechToText/
    ├── App/
    │   ├── SpeechToTextApp.swift      # @main entry point with NSApplicationDelegateAdaptor
    │   └── AppDelegate.swift          # Menu bar setup, settings window management
    ├── Core/
    │   ├── HotkeyManager.swift        # Placeholder
    │   ├── AudioRecorder.swift        # Placeholder
    │   ├── WhisperService.swift       # Placeholder
    │   ├── ClaudeService.swift        # Placeholder
    │   └── PasteManager.swift         # Placeholder
    ├── Settings/
    │   ├── SettingsManager.swift      # Placeholder
    │   └── SettingsView.swift         # Placeholder SwiftUI view
    ├── Assets.xcassets/
    │   ├── Contents.json
    │   └── AppIcon.appiconset/
    ├── Info.plist
    └── SpeechToText.entitlements
```

### Info.plist Entries
| Key | Value | Purpose |
|-----|-------|---------|
| LSUIElement | YES | Hide from Dock, menu bar only |
| NSMicrophoneUsageDescription | "SpeechToText needs microphone access..." | Microphone permission dialog |
| NSAppleEventsUsageDescription | "SpeechToText needs Apple Events access..." | Paste into other apps |

### Entitlements
| Key | Value | Purpose |
|-----|-------|---------|
| com.apple.security.app-sandbox | NO | Required for CGEventTap and global hotkeys |
| com.apple.security.device.audio-input | YES | Microphone recording |
| com.apple.security.hardened-runtime | YES | Security hardening |

### Build Configuration
- Swift version: 5.0
- macOS deployment target: 13.0
- Hardened runtime: enabled
- Code signing: automatic
- Build verified: **SUCCESS**
