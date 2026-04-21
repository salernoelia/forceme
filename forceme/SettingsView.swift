import SwiftUI

struct SettingsView: View {
    var engine: SpeechEngine
    var settings: SettingsStore
    var onSave: () -> Void

    @State private var selectedModel: SettingsStore.WhisperModel
    @State private var selectedVoice: SettingsStore.Voice

    init(engine: SpeechEngine, settings: SettingsStore, onSave: @escaping () -> Void) {
        self.engine = engine
        self.settings = settings
        self.onSave = onSave
        _selectedModel = State(initialValue: settings.whisperModel)
        _selectedVoice = State(initialValue: settings.voice)
    }

    var body: some View {
        NavigationStack {
            List {
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
    SettingsView(engine: SpeechEngine(), settings: SettingsStore()) {}
}
