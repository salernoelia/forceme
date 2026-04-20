import SwiftUI

struct RootView: View {
    @State private var engine = SpeechEngine()
    @State private var settings = SettingsStore()
    @State private var selectedTab: Tab = .demo

    enum Tab { case demo, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Demo", systemImage: "mic.fill", value: .demo) {
                VoiceLoopView(engine: engine, settings: settings)
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView(engine: engine, settings: settings, onSave: {
                    selectedTab = .demo
                })
            }
        }
        .task { await engine.requestPermissionAndLoad(settings: settings) }
    }
}

#Preview {
    RootView()
}
