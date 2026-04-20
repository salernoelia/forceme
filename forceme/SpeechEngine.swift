import Foundation
import AVFoundation
import WhisperKit
import TTSKit

@MainActor
@Observable
final class SpeechEngine {

    enum State {
        case idle
        case loadingModels
        case recording
        case transcribing
        case speaking
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var transcript: String = ""

    private var whisper: WhisperKit?
    private var tts: TTSKit?
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func loadModels() async {
        state = .loadingModels
        do {
            async let w = WhisperKit(WhisperKitConfig(model: "openai_whisper-large-v3-v20240930_626MB"))
            async let t = TTSKit(TTSKitConfig(model: .qwen3TTS_0_6b))
            (whisper, tts) = try await (w, t)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        state = .recording
    }

    func stopRecordingAndProcess() async {
        recorder?.stop()
        recorder = nil
        guard let url = recordingURL else { return }

        state = .transcribing
        do {
            guard let whisper else { throw EngineError.notLoaded }
            let results = try await whisper.transcribe(audioPath: url.path)
            let text = results.map(\.text).joined(separator: " ")
            transcript = text
            try FileManager.default.removeItem(at: url)

            guard !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                state = .idle
                return
            }

            state = .speaking
            guard let tts else { throw EngineError.notLoaded }
            try await tts.play(text: text)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func cancelError() { state = .idle }
}

private enum EngineError: LocalizedError {
    case notLoaded
    var errorDescription: String? { "Models not loaded yet." }
}
