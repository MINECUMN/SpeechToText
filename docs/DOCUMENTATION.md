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

---

## Step 2: HotkeyManager

### What was implemented
- Global hotkey detection via `CGEventTap` (requires Accessibility permission)
- Push-to-talk pattern: key down starts recording, key up/control release stops recording
- Configurable key codes (default: Control+1 = Standard, Control+2 = Social Media)
- Delegate protocol (`HotkeyManagerDelegate`) for recording start/stop events
- Auto-re-enable on tap timeout/user disable

### Key Technical Details
- Uses `CGEvent.tapCreate` with `cgSessionEventTap` placement
- Monitors `.keyDown`, `.keyUp`, and `.flagsChanged` events
- Control key release also triggers stop (via `.flagsChanged`)
- Free-function callback bridges to class via `Unmanaged` pointer
- `SpeechMode` enum: `.standard` and `.socialMedia`

### Permissions Required
- **Accessibility**: System Preferences → Privacy & Security → Accessibility → SpeechToText must be enabled
- Without this permission, `CGEvent.tapCreate` returns `nil`

### Files Modified
- `SpeechToText/Core/HotkeyManager.swift` — full implementation
