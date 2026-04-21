import SwiftUI
import PhotosUI

struct LLMDemoView: View {
    var gemma: GemmaEngine

    @State private var prompt: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                switch gemma.state {
                case .idle:
                    notLoadedView
                case .downloading(let p):
                    loadingOverlay(message: "Downloading model…", progress: p)
                case .loading:
                    loadingOverlay(message: "Loading Gemma…", progress: nil)
                case .ready, .generating:
                    chatView
                case .error(let msg):
                    errorView(msg)
                }
            }
            .navigationTitle("Gemma 4")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var notLoadedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Gemma 4 E2B not loaded")
                .font(.title3)
            Text("Load from Settings → Gemma Model")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                    }

                    if !gemma.output.isEmpty {
                        Text(gemma.output)
                            .font(.body)
                            .padding(.horizontal, 20)
                            .animation(.easeInOut, value: gemma.output)
                    }

                    if case .generating = gemma.state {
                        ProgressView()
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: selectedImage == nil ? "photo" : "photo.fill")
                        .font(.system(size: 20))
                        
                }

                TextField("Ask anything…", text: $prompt, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)

                Button(action: runInference) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(canSend ? .primary : .quaternary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                guard let item,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let img = UIImage(data: data) else { return }
                withAnimation { selectedImage = img }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Dismiss") { gemma.cancelError() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func loadingOverlay(message: String, progress: Double?) -> some View {
        VStack(spacing: 20) {
            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                    .tint(.primary)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView().scaleEffect(1.4)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var canSend: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        gemma.state == .ready
    }

    private func runInference() {
        let p = prompt
        let img = selectedImage
        prompt = ""
        Task { await gemma.generate(image: img, prompt: p) }
    }
}

#Preview {
    LLMDemoView(gemma: GemmaEngine())
}
