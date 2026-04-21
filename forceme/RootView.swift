import SwiftUI

struct RootView: View {
    @State private var engine = SpeechEngine()
    @State private var gemma = GemmaEngine()
    @State private var settings = SettingsStore()
    @State private var selectedTab: AppTab = .voice

    enum AppTab { case voice, llm, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            VoiceLoopView(engine: engine, settings: settings)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("Voice", systemImage: "mic.fill") }
                .tag(AppTab.voice)

            LLMDemoView(gemma: gemma)
                .tabItem { Label("Gemma", systemImage: "brain") }
                .tag(AppTab.llm)

            SettingsView(engine: engine, gemma: gemma, settings: settings, onSave: { selectedTab = .voice })
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .task { await engine.requestPermissionAndLoad(settings: settings) }
    }
}

#Preview {
    RootView()
}
