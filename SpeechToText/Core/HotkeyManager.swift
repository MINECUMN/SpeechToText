import Cocoa
import Carbon.HIToolbox

enum SpeechMode {
    case standard
    case socialMedia
}

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyManager(_ manager: HotkeyManager, didStartRecordingForMode mode: SpeechMode)
    func hotkeyManager(_ manager: HotkeyManager, didStopRecordingForMode mode: SpeechMode)
}

final class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRecording = false
    private var activeMode: SpeechMode?

    // Configurable keycodes (default: 1 = kVK_ANSI_1, 2 = kVK_ANSI_2)
    var standardKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_1)
    var socialMediaKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_2)

    func start() -> Bool {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

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

    fileprivate func handleKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard flags.contains(.maskControl), !isRecording else { return }

        let mode: SpeechMode?
        if keyCode == standardKeyCode {
            mode = .standard
        } else if keyCode == socialMediaKeyCode {
            mode = .socialMedia
        } else {
            mode = nil
        }

        guard let detectedMode = mode else { return }
        isRecording = true
        activeMode = detectedMode
        delegate?.hotkeyManager(self, didStartRecordingForMode: detectedMode)
    }

    fileprivate func handleKeyUp(keyCode: CGKeyCode) {
        guard isRecording else { return }
        guard keyCode == standardKeyCode || keyCode == socialMediaKeyCode else { return }

        let mode = activeMode ?? .standard
        isRecording = false
        activeMode = nil
        delegate?.hotkeyManager(self, didStopRecordingForMode: mode)
    }

    fileprivate func handleFlagsChanged(flags: CGEventFlags) {
        // If Control was released while recording, stop
        if isRecording && !flags.contains(.maskControl) {
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
        manager.handleKeyDown(keyCode: keyCode, flags: flags)

    case .keyUp:
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        manager.handleKeyUp(keyCode: keyCode)

    case .flagsChanged:
        manager.handleFlagsChanged(flags: event.flags)

    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        // Re-enable the tap
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }

    default:
        break
    }

    return Unmanaged.passRetained(event)
}
