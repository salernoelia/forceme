import SwiftUI

struct MotivationSelector: View {
    var onSelect: (Int) -> Void

    @State private var selectedLevel: Int?
    @State private var submitted = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Motivation level")
                .font(.caption)
                .kerning(1.5)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(fillColor(for: level))
                        .overlay(
                            Circle()
                                .strokeBorder(borderColor(for: level), lineWidth: 1.5)
                        )
                        .frame(width: 38, height: 38)
                        .scaleEffect(scale(for: level))
                        .contentShape(Circle())
                        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: selectedLevel)
                        .onTapGesture {
                            guard !submitted else { return }
                            selectedLevel = level
                        }
                }
            }

            if let selectedLevel {
                Text(label(for: selectedLevel))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .transition(.opacity)
            }

            Button(action: submit) {
                Text("Continue")
                    .font(.body.weight(.medium))
                    .foregroundStyle(softOrange.opacity(selectedLevel == nil ? 0.45 : 1.0))
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

    private func fillColor(for level: Int) -> Color {
        guard let selectedLevel else { return .clear }
        return level <= selectedLevel ? .primary : .clear
    }

    private func scale(for level: Int) -> CGFloat {
        guard let selectedLevel else { return 1.0 }
        return selectedLevel == level ? 1.06 : 1.0
    }

    private func borderColor(for level: Int) -> Color {
        guard let selectedLevel else { return Color.primary.opacity(0.28) }
        return level <= selectedLevel ? Color.primary.opacity(0.0) : Color.primary.opacity(0.28)
    }

    private var softOrange: Color {
        Color(hue: 0.06, saturation: 0.70, brightness: 0.92)
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
