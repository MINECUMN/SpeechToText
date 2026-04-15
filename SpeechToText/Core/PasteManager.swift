import Cocoa

final class PasteManager {
    private var previousApp: NSRunningApplication?

    func saveFrontmostApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    func pasteText(_ text: String) {
        // Set clipboard content
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Re-activate the previously focused app
        if let app = previousApp {
            app.activate()
        }

        // Small delay to ensure app is focused before pasting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.simulatePaste()
            self?.previousApp = nil
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Cmd+V keydown
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return }
        keyDown.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)

        // Cmd+V keyup
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        keyUp.flags = .maskCommand
        keyUp.post(tap: .cghidEventTap)
    }
}
