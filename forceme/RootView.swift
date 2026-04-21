import SwiftUI

struct RootView: View {
    @State private var speech = SpeechEngine()
    @State private var gemma = GemmaEngine()
    @State private var settings = SettingsStore()
    @State private var session: SessionEngine?
    @State private var isBooting = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if isBooting {
                bootView
            } else if !settings.onboardingComplete {
                OnboardingView(speech: speech, settings: settings) {
                    session = SessionEngine(speech: speech, gemma: gemma)
                }
                .transition(.opacity)
            } else if let session {
                FocusView(session: session, gemma: gemma, settings: settings)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isBooting)
        .animation(.easeInOut(duration: 0.4), value: settings.onboardingComplete)
        .task {
            await speech.requestPermissionAndLoad(settings: settings)
            if gemma.wasDownloaded {
                Task { await gemma.load() }
            }
            withAnimation {
                isBooting = false
                if settings.onboardingComplete {
                    session = SessionEngine(speech: speech, gemma: gemma)
                }
            }
        }
    }

    private var bootView: some View {
        VStack(spacing: 20) {
            Text("Tallivity")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(.primary)
            ProgressView()
                .scaleEffect(1.2)
            Text(speech.loadingMessage)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .animation(.easeInOut, value: speech.loadingMessage)
        }
    }
}

#Preview {
    RootView()
}
