import SwiftUI

struct SettingsView: View {
    var gemma: GemmaEngine
    var settings: SettingsStore

    @State private var selectedModel: SettingsStore.WhisperModel
    @State private var selectedVoice: SettingsStore.Voice
    @State private var editingName = false
    @State private var nameInput: String = ""
    @Environment(\.dismiss) private var dismiss

    init(gemma: GemmaEngine, settings: SettingsStore) {
        self.gemma = gemma
        self.settings = settings
        _selectedModel = State(initialValue: settings.whisperModel)
        _selectedVoice = State(initialValue: settings.voice)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    nameRow
                }

                Section("Models") {
                    gemmaRow
                }

                Section("Speech model") {
                    ForEach(SettingsStore.WhisperModel.allCases) { model in
                        checkRow(title: model.displayName, selected: selectedModel == model) {
                            selectedModel = model
                            settings.whisperModel = model
                        }
                    }
                }

                Section("Voice") {
                    ForEach(SettingsStore.Voice.allCases) { voice in
                        checkRow(title: voice.displayName, selected: selectedVoice == voice) {
                            selectedVoice = voice
                            settings.voice = voice
                        }
                    }
                }

                Section("Diagnostics") {
                    NavigationLink("Voice demo") {
                        VoiceDemoWrapper(settings: settings)
                    }
                    NavigationLink("Gemma chat") {
                        LLMDemoView(gemma: gemma)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var nameRow: some View {
        HStack {
            Text("Name")
            Spacer()
            if editingName {
                TextField("First name", text: $nameInput)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .onSubmit { saveName() }
                Button("Save") { saveName() }
                    .font(.caption.weight(.medium))
            } else {
                Text(settings.userName.isEmpty ? "Not set" : settings.userName)
                    .foregroundStyle(.secondary)
                Button("Edit") {
                    nameInput = settings.userName
                    editingName = true
                }
                .font(.caption.weight(.medium))
            }
        }
    }

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
                ProgressView().scaleEffect(0.8)
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
        case .idle:                 "Not downloaded"
        case .downloading(let p):  "Downloading \(Int(p * 100))%…"
        case .loading:              "Loading…"
        case .ready, .generating:  "Ready"
        case .error(let msg):       msg
        }
    }

    private func checkRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private func saveName() {
        settings.userName = nameInput.trimmingCharacters(in: .whitespaces)
        editingName = false
    }
}

// MARK: - Voice demo wrapper (uses SpeechEngine independently)

struct VoiceDemoWrapper: View {
    var settings: SettingsStore
    @State private var engine = SpeechEngine()

    var body: some View {
        VoiceLoopView(engine: engine, settings: settings)
            .task { await engine.requestPermissionAndLoad(settings: settings) }
            .navigationTitle("Voice demo")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(gemma: GemmaEngine(), settings: SettingsStore())
}
