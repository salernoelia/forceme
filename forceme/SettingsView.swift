import SwiftUI

struct SettingsView: View {
    var engine: SpeechEngine
    var gemma: GemmaEngine
    var settings: SettingsStore
    var onSave: () -> Void

    @State private var selectedModel: SettingsStore.WhisperModel
    @State private var selectedVoice: SettingsStore.Voice

    init(engine: SpeechEngine, gemma: GemmaEngine, settings: SettingsStore, onSave: @escaping () -> Void) {
        self.engine = engine
        self.gemma = gemma
        self.settings = settings
        self.onSave = onSave
        _selectedModel = State(initialValue: settings.whisperModel)
        _selectedVoice = State(initialValue: settings.voice)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Gemma model") {
                    gemmaRow
                }

                Section("Speech model") {
                    ForEach(SettingsStore.WhisperModel.allCases) { model in
                        row(
                            title: model.displayName,
                            selected: selectedModel == model
                        ) { selectedModel = model }
                    }
                }

                Section("Voice") {
                    ForEach(SettingsStore.Voice.allCases) { voice in
                        row(
                            title: voice.displayName,
                            selected: selectedVoice == voice
                        ) { selectedVoice = voice }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await engine.applySettings(
                                model: selectedModel,
                                voice: selectedVoice,
                                settings: settings
                            )
                        }
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
        }
    }

    @ViewBuilder
    private var gemmaRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gemma 4 E2B · 4-bit · 3.6 GB")
                Text(gemmaStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if case .downloading(let p) = gemma.state {
                ProgressView(value: p)
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            } else if case .loading = gemma.state {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !gemma.isLoaded {
                Button("Download") { Task { await gemma.load() } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }

    private var gemmaStatusText: String {
        switch gemma.state {
        case .idle:                  "Not downloaded"
        case .downloading(let p):   "Downloading \(Int(p * 100))%…"
        case .loading:               "Loading…"
        case .ready, .generating:   "Ready"
        case .error(let msg):        msg
        }
    }

    private var hasChanges: Bool {
        selectedModel != settings.whisperModel || selectedVoice != settings.voice
    }

    private func row(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

#Preview {
    SettingsView(engine: SpeechEngine(), gemma: GemmaEngine(), settings: SettingsStore()) {}
}
