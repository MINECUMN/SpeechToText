import Foundation

final class ClaudeService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5-20251001"
    private let maxTokens = 1024
    private let apiVersion = "2023-06-01"

    private let standardSystemPrompt = """
        You are a text polishing assistant. The user has dictated a message via voice. \
        Your task is to clean up the transcription: fix grammar, improve flow and readability, \
        remove filler words and repetitions. Keep the original meaning and language \
        (German or English, match the input). Keep the same tone and register. \
        Output ONLY the improved text, nothing else.
        """

    private func socialMediaSystemPrompt(emojiCount: Int) -> String {
        """
        Du bist ein minimaler Text-Bereiniger. Der Nutzer hat eine Nachricht per Sprache diktiert. \
        Deine EINZIGEN Aufgaben: \
        1. Behebe offensichtliche Tipp- und Grammatikfehler. \
        2. Entferne Füllwörter (ähm, also, halt, sozusagen, basically, like, um). \
        3. Füge genau \(emojiCount) Emojis passend im Text ein. \
        STRIKTE REGELN — bei Verstoß ist die Ausgabe UNGÜLTIG: \
        - NIEMALS neue Sätze, Phrasen, Wörter oder Ideen hinzufügen. \
        - NIEMALS umformulieren, erweitern, ausschmücken oder verlängern. \
        - NIEMALS Hashtags, Call-to-Actions oder Fragen ergänzen. \
        - Die Anzahl der Sätze in der Ausgabe MUSS exakt der Anzahl im Input entsprechen. \
        - Dein Output darf NICHT länger sein als der Input (nur Emojis als Zusatz erlaubt). \
        - Sprache des Inputs beibehalten (Deutsch oder Englisch). \
        - Gib NUR den bereinigten Text mit Emojis aus, nichts anderes.
        """
    }

    private let emailSystemPrompt = """
        Du bist ein E-Mail-Formatierungs-Assistent. Der Nutzer hat eine Nachricht per Sprache diktiert. \
        Deine Aufgabe: \
        1. Korrigiere Rechtschreibung und Grammatik. \
        2. Formatiere den Text mit folgender Struktur: \
           - Anrede (z.B. "Sehr geehrte/r ...", "Liebe/r ...") als eigener Absatz \
           - Hauptteil als neuer Absatz, bei längeren Texten in mehrere Absätze untergliedert \
           - Ein abschließender Satz als Schlussphase (z.B. "Ich freue mich auf Ihre Rückmeldung.") \
        3. Verwende eine weiche, freundliche Business-Sprache — professionell aber nicht steif. \
        REGELN: \
        - KEINE Signatur, KEINE Grußformel wie "Mit freundlichen Grüßen", KEIN Name am Ende. \
        - Erfinde KEINE neuen Inhalte, Argumente oder Informationen. \
        - Verwende NUR das, was der Nutzer gesagt hat. \
        - Halte die Sprache des Inputs bei (Deutsch oder Englisch). \
        - Gib NUR die formatierte E-Mail aus, nichts anderes.
        """

    func enhance(text: String, mode: SpeechMode, apiKey: String, emojiCount: Int = 3) async throws -> String {
        let systemPrompt: String
        switch mode {
        case .standard:
            systemPrompt = standardSystemPrompt
        case .socialMedia:
            systemPrompt = socialMediaSystemPrompt(emojiCount: emojiCount)
        case .email:
            systemPrompt = emailSystemPrompt
        }

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let enhancedText = firstBlock["text"] as? String else {
            throw ClaudeError.parseError
        }

        return enhancedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ClaudeError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let code, let message):
            return "Claude API error (\(code)): \(message)"
        case .parseError:
            return "Failed to parse Claude API response"
        }
    }
}
