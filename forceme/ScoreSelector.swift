import SwiftUI

struct ScoreSelector: View {
    var onSelect: (Int) -> Void

    @State private var selected: Int? = nil
    @State private var scales: [CGFloat] = Array(repeating: 1.0, count: 5)
    @State private var submitted = false

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
                        .onTapGesture { guard !submitted else { return }; tap(i) }
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
    }

    private func tap(_ i: Int) {
        selected = i
        for j in 0..<i {
            let delay = Double(j) * 0.06
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.38)) {
                    scales[j] = 1.45
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.55)) {
                        scales[j] = 1.0
                    }
                }
            }
        }
        let submitDelay = Double(i) * 0.06 + 0.45
        DispatchQueue.main.asyncAfter(deadline: .now() + submitDelay) {
            submitted = true
            onSelect(i)
        }
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
