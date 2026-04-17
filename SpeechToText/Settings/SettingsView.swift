import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    @State private var openAIKeyInput: String = ""
    @State private var claudeKeyInput: String = ""
    @State private var showOpenAIKey = false
    @State private var showClaudeKey = false

    private let languages = [
        ("auto", "Auto-Detect"),
        ("de", "Deutsch"),
        ("en", "English")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "mic.fill")
                    .font(.title2)
                Text("SpeechToText Settings")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    apiKeysSection
                    Divider()
                    hotkeysSection
                    Divider()
                    languageSection
                    Divider()
                    emojiSection
                    Divider()
                    generalSection
                }
            }
        }
        .padding(24)
        .frame(width: 450, height: 520)
        .onAppear {
            openAIKeyInput = settings.openAIApiKey ?? ""
            claudeKeyInput = settings.claudeApiKey ?? ""
        }
    }

    // MARK: - API Keys Section

    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("API Keys", systemImage: "key")
                .font(.headline)

            // OpenAI Key
            VStack(alignment: .leading, spacing: 4) {
                Text("OpenAI API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Group {
                        if showOpenAIKey {
                            TextField("sk-...", text: $openAIKeyInput)
                        } else {
                            SecureField("sk-...", text: $openAIKeyInput)
                        }
                    }
                    .textFieldStyle(.roundedBorder)

                    Button(action: { showOpenAIKey.toggle() }) {
                        Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)

                    Button("Save") {
                        settings.openAIApiKey = openAIKeyInput.isEmpty ? nil : openAIKeyInput
                    }
                    .disabled(openAIKeyInput == (settings.openAIApiKey ?? ""))
                }
                if settings.hasOpenAIKey {
                    Label("Key saved in Keychain", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Claude Key
            VStack(alignment: .leading, spacing: 4) {
                Text("Anthropic (Claude) API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Group {
                        if showClaudeKey {
                            TextField("sk-ant-...", text: $claudeKeyInput)
                        } else {
                            SecureField("sk-ant-...", text: $claudeKeyInput)
                        }
                    }
                    .textFieldStyle(.roundedBorder)

                    Button(action: { showClaudeKey.toggle() }) {
                        Image(systemName: showClaudeKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)

                    Button("Save") {
                        settings.claudeApiKey = claudeKeyInput.isEmpty ? nil : claudeKeyInput
                    }
                    .disabled(claudeKeyInput == (settings.claudeApiKey ?? ""))
                }
                if settings.hasClaudeKey {
                    Label("Key saved in Keychain", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Hotkeys Section

    private var hotkeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hotkeys", systemImage: "keyboard")
                .font(.headline)

            HStack {
                Text("Standard Mode:")
                    .frame(width: 140, alignment: .leading)
                Text(settings.standardHotkeyLabel)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack {
                Text("Social Media Mode:")
                    .frame(width: 140, alignment: .leading)
                Text(settings.socialMediaHotkeyLabel)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack {
                Text("Email Mode:")
                    .frame(width: 140, alignment: .leading)
                Text(settings.emailHotkeyLabel)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            Text("Hold the hotkey to record, release to process and paste.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Language", systemImage: "globe")
                .font(.headline)

            Picker("Whisper Language:", selection: $settings.language) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Emoji Section

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Social Media Mode", systemImage: "face.smiling")
                .font(.headline)

            HStack {
                Text("Emojis per text:")
                Slider(value: Binding(
                    get: { Double(settings.emojiCount) },
                    set: { settings.emojiCount = Int($0) }
                ), in: 1...20, step: 1)
                Text("\(settings.emojiCount)")
                    .frame(width: 30)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("General", systemImage: "gearshape")
                .font(.headline)

            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
        }
    }
}
