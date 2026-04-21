import SwiftUI

struct TimerRingView: View {
    let progress: Double  // 0 = start, 1 = done
    let isWork: Bool

    private var remaining: Double { max(0, 1 - progress) }

    private var sectorColor: Color {
        isWork
            ? Color(hue: 0.06, saturation: 0.82, brightness: 0.95)   // orange
            : Color(hue: 0.36, saturation: 0.55, brightness: 0.72)   // sage green
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2

            ZStack {
                // Dial face
                Circle()
                    .fill(Color(.secondarySystemBackground))

                // Remaining-time sector
                Canvas { ctx, _ in
                    guard remaining > 0 else { return }
                    let startAngle = Angle.degrees(-90)
                    let endAngle = Angle.degrees(-90 + remaining * 360)

                    var path = Path()
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    path.closeSubpath()

                    ctx.fill(path, with: .color(sectorColor))
                }
                .animation(.linear(duration: 0.3), value: remaining)

                // Centre hub
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: size * 0.18, height: size * 0.18)

                Circle()
                    .fill(Color(.tertiaryLabel))
                    .frame(width: size * 0.06, height: size * 0.06)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        TimerRingView(progress: 0.3, isWork: true)
            .frame(width: 240, height: 240)
        TimerRingView(progress: 0.7, isWork: false)
            .frame(width: 240, height: 240)
    }
    .padding(40)
}
