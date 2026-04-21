import SwiftUI

struct ScoreSelector: View {
    var onSelect: (Int) -> Void
    var onTapRate: (() -> Void)? = nil

    @State private var selected: Int? = nil
    @State private var scales: [CGFloat] = Array(repeating: 1.0, count: 5)
    @State private var submitted = false
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 36) {
            Text("Score this round")
                .font(.caption)
                .kerning(1.5)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack(spacing: 18) {
                ForEach(1...5, id: \.self) { i in
                    let filled = selected != nil && i <= selected!
                    Circle()
                        .fill(filled ? Color.primary : Color.clear)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary.opacity(filled ? 0 : 0.28), lineWidth: 1.5)
                        )
                        .frame(width: 38, height: 38)
                        .scaleEffect(scales[i - 1])
                        .onTapGesture {
                            guard !submitted else { return }
                            onTapRate?()
                            tap(i)
                        }
                }
            }

            if let s = selected {
                Text(label(s))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selected)
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }

    private func tap(_ i: Int) {
        animationTask?.cancel()
        selected = i
        animationTask = Task { @MainActor in
            for j in 0..<i {
                if Task.isCancelled { return }
                if j > 0 {
                    try? await Task.sleep(for: .seconds(0.06))
                }
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.38)) {
                    setScale(1.45, at: j)
                }
                try? await Task.sleep(for: .seconds(0.18))
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.36, dampingFraction: 0.55)) {
                    setScale(1.0, at: j)
                }
            }

            try? await Task.sleep(for: .seconds(0.21))
            if Task.isCancelled { return }
            submitted = true
            onSelect(i)
        }
    }

    private func setScale(_ value: CGFloat, at index: Int) {
        guard scales.indices.contains(index) else { return }
        scales[index] = value
    }

    private func label(_ score: Int) -> String {
        switch score {
        case 1: return "rough"
        case 2: return "below par"
        case 3: return "decent"
        case 4: return "solid"
        case 5: return "excellent"
        default: return ""
        }
    }
}

#Preview {
    ScoreSelector { score in print("Selected: \(score)") }
        .padding(40)
}
