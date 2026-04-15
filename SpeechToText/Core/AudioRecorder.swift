import AVFoundation

final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private(set) var recordingURL: URL?

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        } else {
            // On macOS 13, permission is requested automatically on first use
            completion(true)
        }
    }

    func startRecording() throws {
        let tempDir = NSTemporaryDirectory()
        let fileName = "speechtotext_\(UUID().uuidString).m4a"
        let url = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        let url = recordingURL
        recorder = nil
        return url
    }

    func cleanup() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }
}
