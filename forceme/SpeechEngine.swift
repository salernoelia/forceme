import Foundation
import AVFoundation
import UIKit
import WhisperKit
import TTSKit

@MainActor
@Observable
final class SpeechEngine {

    enum State {
        case requestingPermission
        case permissionDenied
        case loadingModels(String)
        case idle
        case recording
        case transcribing
        case speaking
        case error(String)
    }

    private(set) var state: State = .requestingPermission
    private(set) var transcript: String = ""
    private(set) var downloadProgress: Double? = nil

    private var whisper: WhisperKit?
    private var tts: TTSKit?
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    private var currentModel: SettingsStore.WhisperModel = .small
    private var currentVoice: SettingsStore.Voice = .dylan

    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

    func requestPermissionAndLoad(settings: SettingsStore) async {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            state = .permissionDenied
            return
        }
        currentModel = settings.whisperModel
        currentVoice = settings.voice
        observeAudioSession()
        await loadModels(model: currentModel, voice: currentVoice)
    }

    func applySettings(model: SettingsStore.WhisperModel, voice: SettingsStore.Voice, settings: SettingsStore) async {
        settings.voice = voice
        currentVoice = voice

        guard model != currentModel else { return }

        settings.whisperModel = model
        currentModel = model
        whisper = nil
        await loadModels(model: model, voice: voice)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func loadModels(model: SettingsStore.WhisperModel, voice: SettingsStore.Voice) async {
        state = .loadingModels("Loading models…")
        try? configureAudioSession()
        downloadProgress = nil
        do {
            async let w = makeWhisper(model: model)
            async let t = makeTTS(voice: voice)
            (whisper, tts) = try await (w, t)
            downloadProgress = nil
            state = .idle
        } catch {
            downloadProgress = nil
            state = .error(error.localizedDescription)
        }
    }

    private func makeWhisper(model: SettingsStore.WhisperModel) async throws -> WhisperKit {
        let w = try await WhisperKit(WhisperKitConfig(model: model.rawValue))
        try await w.loadModels()
        return w
    }

    private func makeTTS(voice: SettingsStore.Voice) async throws -> TTSKit {
        let t = try await TTSKit(TTSKitConfig(model: .qwen3TTS_0_6b))
        _ = try await t.generate(text: "Ready", voice: voice.ttsVoice, language: "english")
        return t
    }

    func startRecording() throws {
        try configureAudioSession()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
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
            try? FileManager.default.removeItem(at: url)

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                state = .idle
                return
            }

            state = .speaking
            guard let tts else { throw EngineError.notLoaded }
            let session = AVAudioSession.sharedInstance()
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
            try await tts.play(text: text, voice: currentVoice.ttsVoice, language: "english")
            try? configureAudioSession()
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func cancelError() { state = .idle }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func observeAudioSession() {
        let nc = NotificationCenter.default

        interruptionObserver = nc.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let typeVal = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }

            Task { @MainActor in
                switch type {
                case .began:
                    if self.state == .recording {
                        self.recorder?.pause()
                    }
                case .ended:
                    let optionsVal = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsVal)
                    if options.contains(.shouldResume) {
                        try? self.configureAudioSession()
                        if self.state == .recording {
                            self.recorder?.record()
                        }
                    }
                @unknown default: break
                }
            }
        }

        routeChangeObserver = nc.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let reasonVal = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonVal) else { return }
            if reason == .oldDeviceUnavailable {
                Task { @MainActor in
                    if self.state == .recording {
                        self.recorder?.pause()
                    }
                }
            }
        }
    }
}

private enum EngineError: LocalizedError {
    case notLoaded
    var errorDescription: String? { "Models not loaded yet." }
}

extension SettingsStore.Voice {
    var ttsVoice: String {
        switch self {
        case .ryan:    "ryan"
        case .aiden:   "aiden"
        case .onoAnna: "ono-anna"
        case .sohee:   "sohee"
        case .eric:    "eric"
        case .dylan:   "dylan"
        case .serena:  "serena"
        case .vivian:  "vivian"
        case .uncleFu: "uncle-fu"
        }
    }
}
