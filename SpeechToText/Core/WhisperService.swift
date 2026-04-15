import Foundation

final class WhisperService {
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioURL)
        var body = Data()

        // model field
        body.appendMultipart(boundary: boundary, name: "model", value: "whisper-1")

        // language field (optional)
        if let lang = language, lang != "auto" {
            body.appendMultipart(boundary: boundary, name: "language", value: lang)
        }

        // response_format
        body.appendMultipart(boundary: boundary, name: "response_format", value: "text")

        // audio file
        body.appendMultipartFile(boundary: boundary, name: "file", filename: audioURL.lastPathComponent, mimeType: "audio/m4a", data: audioData)

        // closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WhisperError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let transcription = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !transcription.isEmpty else {
            throw WhisperError.emptyTranscription
        }

        return transcription
    }
}

enum WhisperError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Whisper API"
        case .apiError(let code, let message):
            return "Whisper API error (\(code)): \(message)"
        case .emptyTranscription:
            return "Whisper returned empty transcription"
        }
    }
}

private extension Data {
    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartFile(boundary: String, name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
