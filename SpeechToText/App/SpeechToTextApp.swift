import SwiftUI
import UserNotifications

@main
struct SpeechToTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - SpeechCoordinator

final class SpeechCoordinator: HotkeyManagerDelegate {
    private let hotkeyManager = HotkeyManager()
    private let audioRecorder = AudioRecorder()
    private let whisperService = WhisperService()
    private let claudeService = ClaudeService()
    private let pasteManager = PasteManager()
    private let settings = SettingsManager.shared
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        hotkeyManager.delegate = self
    }

    func start() {
        // Check for API keys on first run
        if !settings.hasAllKeys {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.appDelegate?.openSettings()
                self?.sendNotification(
                    title: "SpeechToText",
                    body: "API Keys fehlen — bitte in den Einstellungen konfigurieren."
                )
            }
        } else {
            sendNotification(
                title: "SpeechToText bereit",
                body: "\u{2303}1 = Standard \u{00B7} \u{2303}2 = Social Media"
            )
        }

        // Request microphone permission
        audioRecorder.requestPermission { granted in
            if !granted {
                self.sendNotification(
                    title: "Mikrofonzugriff verweigert",
                    body: "Bitte Mikrofonzugriff in Systemeinstellungen aktivieren."
                )
            }
        }

        // Start hotkey listener
        if !hotkeyManager.start() {
            sendNotification(
                title: "Bedienungshilfen-Zugriff erforderlich",
                body: "Bitte SpeechToText in Systemeinstellungen → Datenschutz → Bedienungshilfen aktivieren."
            )
        }
    }

    func stop() {
        hotkeyManager.stop()
    }

    // MARK: - HotkeyManagerDelegate

    func hotkeyManager(_ manager: HotkeyManager, didStartRecordingForMode mode: SpeechMode) {
        pasteManager.saveFrontmostApp()
        appDelegate?.setCurrentMode(mode)
        appDelegate?.updateState(.recording)

        do {
            try audioRecorder.startRecording()
        } catch {
            sendNotification(title: "Aufnahme fehlgeschlagen", body: error.localizedDescription)
            appDelegate?.updateState(mode == .standard ? .idleStandard : .idleSocialMedia)
        }
    }

    func hotkeyManager(_ manager: HotkeyManager, didStopRecordingForMode mode: SpeechMode) {
        guard let audioURL = audioRecorder.stopRecording() else {
            appDelegate?.updateState(mode == .standard ? .idleStandard : .idleSocialMedia)
            return
        }

        appDelegate?.updateState(.processingWhisper)

        Task {
            await processAudio(url: audioURL, mode: mode)
        }
    }

    // MARK: - Processing Pipeline

    private func processAudio(url: URL, mode: SpeechMode) async {
        defer {
            audioRecorder.cleanup()
            DispatchQueue.main.async { [weak self] in
                self?.appDelegate?.updateState(mode == .standard ? .idleStandard : .idleSocialMedia)
            }
        }

        // Step 1: Check API keys
        guard let openAIKey = settings.openAIApiKey, !openAIKey.isEmpty else {
            sendNotification(title: "OpenAI API Key fehlt", body: "Einstellungen öffnen und Key konfigurieren.")
            DispatchQueue.main.async { [weak self] in self?.appDelegate?.openSettings() }
            return
        }

        // Step 2: Transcribe with Whisper
        let transcription: String
        do {
            let lang = settings.language == "auto" ? nil : settings.language
            transcription = try await whisperService.transcribe(audioURL: url, apiKey: openAIKey, language: lang)
        } catch {
            sendNotification(title: "Transkription fehlgeschlagen", body: "\(error.localizedDescription)")
            return
        }

        // Step 3: Enhance with Claude
        DispatchQueue.main.async { [weak self] in
            self?.appDelegate?.updateState(.processingClaude)
        }

        guard let claudeKey = settings.claudeApiKey, !claudeKey.isEmpty else {
            // Fallback: paste raw transcription
            sendNotification(title: "Claude API Key fehlt", body: "Rohtext wird eingefügt.")
            DispatchQueue.main.async { [weak self] in
                self?.pasteManager.pasteText(transcription)
            }
            return
        }

        do {
            let enhanced = try await claudeService.enhance(
                text: transcription,
                mode: mode,
                apiKey: claudeKey,
                emojiCount: settings.emojiCount
            )
            DispatchQueue.main.async { [weak self] in
                self?.pasteManager.pasteText(enhanced)
            }
        } catch {
            // Fallback: paste raw transcription
            sendNotification(
                title: "Textverbesserung fehlgeschlagen",
                body: "Rohtext wird eingefügt: \(error.localizedDescription)"
            )
            DispatchQueue.main.async { [weak self] in
                self?.pasteManager.pasteText(transcription)
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
