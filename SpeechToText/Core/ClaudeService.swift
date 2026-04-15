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
        You are a social media copywriter. The user has dictated a message via voice. \
        Clean up the transcription, improve flow and readability, and add exactly \(emojiCount) emojis \
        placed naturally throughout the text. Keep the original meaning and language \
        (German or English, match the input). Make it engaging and authentic for social media. \
        Output ONLY the final text, nothing else.
        """
    }

    func enhance(text: String, mode: SpeechMode, apiKey: String, emojiCount: Int = 3) async throws -> String {
        let systemPrompt: String
        switch mode {
        case .standard:
            systemPrompt = standardSystemPrompt
        case .socialMedia:
            systemPrompt = socialMediaSystemPrompt(emojiCount: emojiCount)
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
