import Foundation
import Security
import ServiceManagement

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let keychainServiceOpenAI = "tech.minec.SpeechToText.openai"
    private let keychainServiceClaude = "tech.minec.SpeechToText.claude"
    private let keychainAccount = "apikey"

    // MARK: - Published Properties (UserDefaults-backed)

    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "stt_language") }
    }

    @Published var emojiCount: Int {
        didSet { UserDefaults.standard.set(emojiCount, forKey: "stt_emojiCount") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "stt_launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var standardHotkeyLabel: String {
        didSet { UserDefaults.standard.set(standardHotkeyLabel, forKey: "stt_standardHotkey") }
    }

    @Published var socialMediaHotkeyLabel: String {
        didSet { UserDefaults.standard.set(socialMediaHotkeyLabel, forKey: "stt_socialMediaHotkey") }
    }

    @Published var emailHotkeyLabel: String {
        didSet { UserDefaults.standard.set(emailHotkeyLabel, forKey: "stt_emailHotkey") }
    }

    // MARK: - Init

    private init() {
        self.language = UserDefaults.standard.string(forKey: "stt_language") ?? "de"
        self.emojiCount = UserDefaults.standard.object(forKey: "stt_emojiCount") as? Int ?? 3
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "stt_launchAtLogin")
        self.standardHotkeyLabel = UserDefaults.standard.string(forKey: "stt_standardHotkey") ?? "Option+S"
        self.socialMediaHotkeyLabel = UserDefaults.standard.string(forKey: "stt_socialMediaHotkey") ?? "Option+M"
        self.emailHotkeyLabel = UserDefaults.standard.string(forKey: "stt_emailHotkey") ?? "Option+E"
    }

    // MARK: - Keychain API Keys

    var openAIApiKey: String? {
        get { readKeychain(service: keychainServiceOpenAI) }
        set {
            if let key = newValue {
                saveKeychain(service: keychainServiceOpenAI, value: key)
            } else {
                deleteKeychain(service: keychainServiceOpenAI)
            }
            objectWillChange.send()
        }
    }

    var claudeApiKey: String? {
        get { readKeychain(service: keychainServiceClaude) }
        set {
            if let key = newValue {
                saveKeychain(service: keychainServiceClaude, value: key)
            } else {
                deleteKeychain(service: keychainServiceClaude)
            }
            objectWillChange.send()
        }
    }

    var hasOpenAIKey: Bool { openAIApiKey != nil && !openAIApiKey!.isEmpty }
    var hasClaudeKey: Bool { claudeApiKey != nil && !claudeApiKey!.isEmpty }
    var hasAllKeys: Bool { hasOpenAIKey && hasClaudeKey }

    // MARK: - Keychain Helpers

    private func saveKeychain(service: String, value: String) {
        deleteKeychain(service: service)
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readKeychain(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Launch at Login

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("SettingsManager: Launch at login error: \(error)")
            }
        }
    }
}
