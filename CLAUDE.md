# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native macOS menu bar app for push-to-talk speech-to-text with AI text enhancement. Hold Option+S/M to record, release to transcribe (Whisper) + enhance (Claude) + auto-paste.

## Build Commands

```bash
# Build (Debug)
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Debug build

# Build (Release)
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Release build

# Open in Xcode
open SpeechToText.xcodeproj
```

## Architecture

**SpeechCoordinator** (in `SpeechToTextApp.swift`) orchestrates the entire pipeline:

```
HotkeyManager → AudioRecorder → WhisperService → ClaudeService → PasteManager
```

- **HotkeyManager**: CGEventTap for global Option+S / Option+M push-to-talk (maskAlternate)
- **AudioRecorder**: AVAudioRecorder, M4A 16kHz mono, temp files
- **WhisperService**: OpenAI `POST /v1/audio/transcriptions`, multipart upload
- **ClaudeService**: Anthropic `POST /v1/messages`, model `claude-haiku-4-5-20251001`
- **PasteManager**: Saves frontmost app → NSPasteboard → CGEventPost Cmd+V
- **SettingsManager**: Singleton, Keychain for API keys, UserDefaults for prefs
- **AppDelegate**: NSStatusItem with 5 icon states (idle/recording/whisper/claude per mode)

## Key Constraints

- No app sandbox (CGEventTap requires it)
- macOS 13+ deployment target
- No external dependencies — only Apple frameworks + URLSession
- API keys in Keychain, never in code or UserDefaults
- All errors via UserNotifications, no modal dialogs
- Fallback: paste raw Whisper text if Claude fails
