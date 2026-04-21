import SwiftUI

struct RotaryTimePicker: View {
    @Binding var value: Int
    let values: [Int]
    let label: String

    @State private var dragOffset: CGFloat = 0
    private let itemHeight: CGFloat = 50

    private var selectedIndex: Int {
        values.firstIndex(of: value) ?? 0
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .kerning(1.6)
                .textCase(.uppercase)
                .foregroundStyle(.tertiary)

            ZStack {
                // Selection tray
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: itemHeight)
                    .padding(.horizontal, 8)

                // Numbers
                ZStack {
                    ForEach(Array(values.enumerated()), id: \.offset) { idx, val in
                        let relPos = CGFloat(idx - selectedIndex) * itemHeight + dragOffset
                        let dist = abs(relPos / itemHeight)

                        if dist < 2.6 {
                            Text("\(val)")
                                .font(.system(
                                    size: fontSize(dist: dist),
                                    weight: dist < 0.35 ? .semibold : .light,
                                    design: .rounded
                                ))
                                .foregroundStyle(.primary)
                                .opacity(opacity(dist: dist))
                                .scaleEffect(y: perspective(dist: dist))
                                .offset(y: relPos)
                                .animation(.interactiveSpring(), value: dragOffset)
                        }
                    }
                }
                .frame(height: itemHeight * 5)
                .clipped()
            }
            .frame(height: itemHeight * 5)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { v in
                        dragOffset = v.translation.height
                    }
                    .onEnded { v in
                        let steps = Int((-v.translation.height / itemHeight).rounded())
                        let newIdx = max(0, min(values.count - 1, selectedIndex + steps))
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            value = values[newIdx]
                            dragOffset = 0
                        }
                    }
            )

            Text("min")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.tertiary)
        }
    }

    private func fontSize(dist: CGFloat) -> CGFloat {
        max(14, 36 - dist * 8)
    }

    private func opacity(dist: CGFloat) -> Double {
        max(0, 1 - Double(dist) * 0.45)
    }

    private func perspective(dist: CGFloat) -> CGFloat {
        max(0.6, 1 - dist * 0.12)
    }
}

#Preview {
    @Previewable @State var focus = 25
    @Previewable @State var brk = 5

    HStack(spacing: 48) {
        RotaryTimePicker(
            value: $focus,
            values: Array(stride(from: 5, through: 90, by: 5)),
            label: "Focus"
        )
        .frame(width: 100)

        RotaryTimePicker(
            value: $brk,
            values: Array(stride(from: 1, through: 30, by: 1)),
            label: "Break"
        )
        .frame(width: 100)
    }
    .padding(40)
}
