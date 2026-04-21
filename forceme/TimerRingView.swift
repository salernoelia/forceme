import SwiftUI

struct TimerRingView: View {
    let progress: Double   // 0 = start, 1 = done
    let isWork: Bool

    @State private var pulsing = false

    private var remaining: Double { max(0, min(1, 1 - progress)) }

    private var arcColor: Color {
        isWork
            ? Color(hue: 0.06, saturation: 0.70, brightness: 0.92)
            : Color(hue: 0.36, saturation: 0.42, brightness: 0.70)
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = size * 0.10

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: remaining)
                    .stroke(
                        arcColor.opacity(pulsing ? 0.78 : 1.0),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: remaining)
                    .animation(
                        .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                        value: pulsing
                    )
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                pulsing = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        TimerRingView(progress: 0.25, isWork: true)
            .frame(width: 220, height: 220)
        TimerRingView(progress: 0.6, isWork: false)
            .frame(width: 220, height: 220)
    }
    .padding(40)
    .background(Color(.systemBackground))
}
