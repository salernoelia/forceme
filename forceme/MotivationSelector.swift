import SwiftUI

struct MotivationSelector: View {
    var onSelect: (Int) -> Void

    @State private var selectedLevel: Int?
    @State private var submitted = false

    var body: some View {
        VStack(spacing: 34) {
            Text("Motivation level")
                .font(.caption)
                .kerning(1.5)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ZStack {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .strokeBorder(strokeColor(for: level), lineWidth: ringWidth(for: level))
                        .frame(width: ringSize(for: level), height: ringSize(for: level))
                        .scaleEffect(scale(for: level))
                        .opacity(opacity(for: level))
                        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: selectedLevel)
                        .onTapGesture {
                            guard !submitted else { return }
                            selectedLevel = level
                        }
                }
            }
            .frame(width: 250, height: 250)

            if let selectedLevel {
                Text(label(for: selectedLevel))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .transition(.opacity)
            }

            Button(action: submit) {
                Text("Continue")
                    .font(.body.weight(.medium))
                    .foregroundStyle(selectedLevel == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedLevel == nil || submitted)
            .padding(.horizontal, 10)
        }
    }

    private func submit() {
        guard let selectedLevel else { return }
        submitted = true
        onSelect(selectedLevel)
    }

    private func ringSize(for level: Int) -> CGFloat {
        CGFloat(70 + level * 34)
    }

    private func ringWidth(for level: Int) -> CGFloat {
        selectedLevel == level ? 7 : 3
    }

    private func strokeColor(for level: Int) -> Color {
        if let selectedLevel {
            if level <= selectedLevel {
                return Color.primary
            }
            return Color.primary.opacity(0.18)
        }
        return Color.primary.opacity(0.28)
    }

    private func opacity(for level: Int) -> Double {
        guard let selectedLevel else { return 1.0 }
        return level <= selectedLevel ? 1.0 : 0.55
    }

    private func scale(for level: Int) -> CGFloat {
        guard let selectedLevel else { return 1.0 }
        return selectedLevel == level ? 1.06 : 1.0
    }

    private func label(for level: Int) -> String {
        switch level {
        case 1: return "low"
        case 2: return "warming up"
        case 3: return "steady"
        case 4: return "locked in"
        case 5: return "all in"
        default: return ""
        }
    }
}

#Preview {
    MotivationSelector { _ in }
        .padding(30)
}
