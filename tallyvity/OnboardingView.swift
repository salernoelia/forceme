import SwiftUI

struct OnboardingView: View {
    var speech: SpeechEngine
    var settings: SettingsStore
    var onComplete: () -> Void

    @State private var name: String = ""
    @State private var step: Step = .intro
    @FocusState private var fieldFocused: Bool

    enum Step { case intro, downloading, nameInput, done }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                switch step {
                case .intro:
                    introContent
                case .downloading:
                    downloadingContent
                case .nameInput:
                    nameContent
                case .done:
                    doneContent
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .animation(.easeInOut(duration: 0.4), value: step)
    }

    private var introContent: some View {
        VStack(spacing: 32) {
            Text("Tallivity")
                .font(.system(size: 34, weight: .light, design: .rounded))
                .foregroundStyle(.primary)

            Text("25-minute focused work sessions.\nVoice-first. No interruptions. All local.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 8) {
                Text("Requires a one-time download of ~820 MB")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Speech recognition (~216 MB) and voice synthesis (~600 MB).\nModels run entirely on your device.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: startDownload) {
                Text("Download & get started")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var downloadingContent: some View {
        VStack(spacing: 32) {
            Text("Setting up your models")
                .font(.title3.weight(.regular))
                .foregroundStyle(.primary)

            VStack(spacing: 16) {
                if let progress = speech.downloadProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.primary)
                } else {
                    BouncingDots(color: .secondary)
                }

                Text(speech.loadingMessage.isEmpty ? "Loading…" : speech.loadingMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("This takes a few minutes on first launch.\nModels are cached — future launches are fast.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .onChange(of: speech.state) { _, newState in
            if case .idle = newState {
                withAnimation { step = .nameInput }
            }
        }
    }

    private var nameContent: some View {
        VStack(spacing: 28) {
            Text("What's your name?")
                .font(.title3.weight(.regular))
                .foregroundStyle(.primary)

            Text("Used only for the closing sentence at session end.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            TextField("First name", text: $name)
                .font(.title3)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: confirmName) {
                Text("Continue")
                    .font(.body.weight(.medium))
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear { fieldFocused = true }
    }

    private var doneContent: some View {
        VStack(spacing: 24) {
            Text("Ready, \(settings.userName).")
                .font(.title3.weight(.regular))
                .foregroundStyle(.primary)

            Text("You can always change your name in Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func startDownload() {
        withAnimation { step = .downloading }
        Task { await speech.requestPermissionAndLoad(settings: settings) }
    }

    private func confirmName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        settings.userName = trimmed
        settings.onboardingComplete = true
        withAnimation { step = .done }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete()
        }
    }
}

#Preview {
    OnboardingView(speech: SpeechEngine(), settings: SettingsStore()) {}
}
