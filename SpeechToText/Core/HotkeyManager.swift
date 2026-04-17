import Cocoa
import Carbon.HIToolbox

enum SpeechMode {
    case standard
    case socialMedia
    case email
}

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyManager(_ manager: HotkeyManager, didStartRecordingForMode mode: SpeechMode)
    func hotkeyManager(_ manager: HotkeyManager, didStopRecordingForMode mode: SpeechMode)
}

final class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    fileprivate var isRecording = false
    fileprivate var activeMode: SpeechMode?

    // Option+S = Standard Mode, Option+M = Social Media Mode, Option+E = Email Mode
    fileprivate let standardKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_S)    // 1
    fileprivate let socialMediaKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_M) // 46
    fileprivate let emailKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_E)       // 14

    func start() -> Bool {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: hotkeyCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("HotkeyManager: Failed to create event tap. Accessibility permission required.")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("HotkeyManager: Event tap created and enabled.")
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// Returns true if the event was handled and should be swallowed
    fileprivate func handleKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        // Require Option (Alt) modifier, reject if Command/Control also held
        let optionOnly = flags.contains(.maskAlternate)
            && !flags.contains(.maskCommand)
            && !flags.contains(.maskControl)

        guard optionOnly else { return false }

        let mode: SpeechMode?
        if keyCode == standardKeyCode {
            mode = .standard
        } else if keyCode == socialMediaKeyCode {
            mode = .socialMedia
        } else if keyCode == emailKeyCode {
            mode = .email
        } else {
            return false
        }

        guard let detectedMode = mode else { return false }

        // Already recording — still swallow the repeated key event
        if isRecording { return true }

        isRecording = true
        activeMode = detectedMode
        delegate?.hotkeyManager(self, didStartRecordingForMode: detectedMode)
        return true
    }

    /// Returns true if the event was handled and should be swallowed
    fileprivate func handleKeyUp(keyCode: CGKeyCode) -> Bool {
        guard isRecording else { return false }
        guard keyCode == standardKeyCode || keyCode == socialMediaKeyCode || keyCode == emailKeyCode else { return false }

        let mode = activeMode ?? .standard
        isRecording = false
        activeMode = nil
        delegate?.hotkeyManager(self, didStopRecordingForMode: mode)
        return true
    }

    fileprivate func handleFlagsChanged(flags: CGEventFlags) {
        // If Option key was released during recording, stop
        if isRecording && !flags.contains(.maskAlternate) {
            let mode = activeMode ?? .standard
            isRecording = false
            activeMode = nil
            delegate?.hotkeyManager(self, didStopRecordingForMode: mode)
        }
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()

    switch type {
    case .keyDown:
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        if manager.handleKeyDown(keyCode: keyCode, flags: flags) {
            return nil // Swallow — don't pass to active app
        }

    case .keyUp:
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        if manager.handleKeyUp(keyCode: keyCode) {
            return nil // Swallow
        }

    case .flagsChanged:
        manager.handleFlagsChanged(flags: event.flags)

    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }

    default:
        break
    }

    return Unmanaged.passRetained(event)
}
