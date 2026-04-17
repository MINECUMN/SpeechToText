import Cocoa
import SwiftUI

enum AppState {
    case idleStandard
    case idleSocialMedia
    case idleEmail
    case recording
    case processingWhisper
    case processingClaude
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var currentMode: SpeechMode = .standard
    private(set) var appState: AppState = .idleStandard
    private var coordinator: SpeechCoordinator?

    // Menu items that need updating
    private var standardModeItem: NSMenuItem!
    private var socialMediaModeItem: NSMenuItem!
    private var emailModeItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        coordinator = SpeechCoordinator(appDelegate: self)
        coordinator?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon()

        let menu = NSMenu()

        standardModeItem = NSMenuItem(title: "Standard Mode (⌥S)", action: #selector(selectStandardMode), keyEquivalent: "")
        standardModeItem.target = self
        menu.addItem(standardModeItem)

        socialMediaModeItem = NSMenuItem(title: "Social Media Mode (⌥M)", action: #selector(selectSocialMediaMode), keyEquivalent: "")
        socialMediaModeItem.target = self
        menu.addItem(socialMediaModeItem)

        emailModeItem = NSMenuItem(title: "Email Mode (⌥E)", action: #selector(selectEmailMode), keyEquivalent: "")
        emailModeItem.target = self
        menu.addItem(emailModeItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateModeCheckmarks()
    }

    // MARK: - State Management

    func updateState(_ state: AppState) {
        appState = state
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusIcon()
        }
    }

    func setCurrentMode(_ mode: SpeechMode) {
        currentMode = mode
        switch mode {
        case .standard:
            appState = .idleStandard
        case .socialMedia:
            appState = .idleSocialMedia
        case .email:
            appState = .idleEmail
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusIcon()
            self?.updateModeCheckmarks()
        }
    }

    // MARK: - Icon Updates

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        switch appState {
        case .idleStandard:
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "SpeechToText - Standard Mode")
            button.title = ""

        case .idleSocialMedia:
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "SpeechToText - Social Media Mode")
            button.title = " \u{1F4F1}" // emoji indicator

        case .idleEmail:
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "SpeechToText - Email Mode")
            button.title = " \u{2709}\u{FE0F}" // envelope indicator

        case .recording:
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Recording...")
            button.title = ""
            // Tint the image red
            if let image = button.image {
                let tinted = image.withSymbolConfiguration(.init(paletteColors: [.red]))
                button.image = tinted
            }

        case .processingWhisper:
            button.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Transcribing...")
            button.title = " ..."

        case .processingClaude:
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Enhancing...")
            button.title = " \u{2728}" // sparkles
        }
    }

    private func updateModeCheckmarks() {
        standardModeItem?.state = (currentMode == .standard) ? .on : .off
        socialMediaModeItem?.state = (currentMode == .socialMedia) ? .on : .off
        emailModeItem?.state = (currentMode == .email) ? .on : .off
    }

    // MARK: - Actions

    @objc private func selectStandardMode() {
        setCurrentMode(.standard)
    }

    @objc private func selectSocialMediaMode() {
        setCurrentMode(.socialMedia)
    }

    @objc private func selectEmailMode() {
        setCurrentMode(.email)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 520),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "SpeechToText Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
