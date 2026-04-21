import SwiftUI

struct RootView: View {
    @State private var engine = SpeechEngine()
    @State private var settings = SettingsStore()
    @State private var selectedTab: AppTab = .demo

    enum AppTab { case demo, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            VoiceLoopView(engine: engine, settings: settings)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("Demo", systemImage: "mic.fill") }
                .tag(AppTab.demo)

            SettingsView(engine: engine, settings: settings, onSave: { selectedTab = .demo })
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .task { await engine.requestPermissionAndLoad(settings: settings) }
    }
}

#Preview {
    RootView()
}
