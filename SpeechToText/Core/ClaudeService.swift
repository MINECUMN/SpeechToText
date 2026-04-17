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
        You are a minimal text cleanup assistant. The user dictated a message via voice. \
        Your ONLY tasks: \
        1. Fix obvious typos and grammar errors. \
        2. Remove filler words (ähm, also, halt, sozusagen, basically, like, um). \
        3. Add exactly \(emojiCount) emojis placed naturally throughout the text. \
        STRICT RULES: \
        - Do NOT add any new sentences, phrases, words or ideas. \
        - Do NOT rephrase, extend or embellish. \
        - Do NOT make the text longer than the original. \
        - The number of sentences in your output MUST equal the number of sentences in the input. \
        - Keep the original language (German or English). \
        - Output ONLY the cleaned text with emojis, nothing else.
        """
    }

    private let emailSystemPrompt = """
        Du bist ein E-Mail-Formatierungs-Assistent. Der Nutzer hat eine Nachricht per Sprache diktiert. \
        Deine Aufgabe: \
        1. Korrigiere Rechtschreibung und Grammatik. \
        2. Formatiere den Text als professionelle E-Mail mit klarer Struktur: \
           - Anrede (z.B. "Sehr geehrte/r ...", "Liebe/r ...") \
           - Hauptteil in sinnvollen Absätzen \
           - Verabschiedung (z.B. "Mit freundlichen Grüßen", "Beste Grüße") \
        3. Verwende eine weiche, freundliche Business-Sprache — professionell aber nicht steif. \
        REGELN: \
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
