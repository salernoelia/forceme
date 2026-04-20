import SwiftUI

struct VoiceLoopView: View {
    @State private var engine = SpeechEngine()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                transcriptSection

                Spacer()

                recordButton
                    .padding(.bottom, 56)
            }
        }
        .task { await engine.loadModels() }
        .alert("Error", isPresented: isError) {
            Button("OK") { engine.cancelError() }
        } message: {
            if case .error(let msg) = engine.state {
                Text(msg)
            }
        }
    }

    @ViewBuilder
    private var transcriptSection: some View {
        VStack(spacing: 16) {
            statusLabel
                .font(.caption)
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: engine.state.label)

            Text(engine.transcript.isEmpty ? "Hold to record" : engine.transcript)
                .font(.title3)
                .fontWeight(.regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(engine.transcript.isEmpty ? .tertiary : .primary)
                .padding(.horizontal, 32)
                .animation(.easeInOut, value: engine.transcript)
        }
    }

    private var statusLabel: some View {
        Text(engine.state.label.uppercased())
            .kerning(1.5)
    }

    private var recordButton: some View {
        Circle()
            .fill(buttonColor)
            .frame(width: 72, height: 72)
            .overlay {
                Image(systemName: buttonIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }
            .scaleEffect(engine.state == .recording ? 1.15 : 1.0)
            .animation(.spring(response: 0.3), value: engine.state == .recording)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPressDown() }
                    .onEnded { _ in onPressUp() }
            )
            .disabled(!engine.state.allowsRecording)
    }

    private var buttonColor: Color {
        switch engine.state {
        case .recording: .red
        case .loadingModels, .transcribing, .speaking: .secondary
        default: .primary
        }
    }

    private var buttonIcon: String {
        switch engine.state {
        case .recording: "stop.fill"
        case .loadingModels: "arrow.down.circle"
        case .transcribing: "waveform"
        case .speaking: "speaker.wave.2.fill"
        default: "mic.fill"
        }
    }

    private var isError: Binding<Bool> {
        Binding(
            get: { if case .error = engine.state { true } else { false } },
            set: { _ in }
        )
    }

    private func onPressDown() {
        guard engine.state.allowsRecording else { return }
        try? engine.startRecording()
    }

    private func onPressUp() {
        guard engine.state == .recording else { return }
        Task { await engine.stopRecordingAndProcess() }
    }
}

extension SpeechEngine.State {
    var label: String {
        switch self {
        case .idle: "ready"
        case .loadingModels: "loading models"
        case .recording: "recording"
        case .transcribing: "transcribing"
        case .speaking: "speaking"
        case .error: "error"
        }
    }

    var allowsRecording: Bool {
        switch self {
        case .idle: true
        default: false
        }
    }
}

extension SpeechEngine.State: Equatable {
    static func == (lhs: SpeechEngine.State, rhs: SpeechEngine.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loadingModels, .loadingModels),
             (.recording, .recording), (.transcribing, .transcribing),
             (.speaking, .speaking): true
        case (.error(let a), .error(let b)): a == b
        default: false
        }
    }
}

#Preview {
    VoiceLoopView()
}
