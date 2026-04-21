import ActivityKit
import WidgetKit
import SwiftUI

struct TallyvityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TallyvityAttributes.self) { context in
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Label {
                        Text(context.state.isWork ? "Focus" : "Break")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: context.state.isWork ? "brain.head.profile" : "cup.and.saucer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(context.attributes.goal)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.endDate, style: .timer)
                        .font(.title2.weight(.light).monospacedDigit())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)

                    Text("Loop \(context.state.loopNumber) of \(context.attributes.totalLoops)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.goal)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: context.state.isWork ? "brain.head.profile" : "cup.and.saucer")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.caption)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endDate, style: .timer)
                        .font(.callout.weight(.medium).monospacedDigit())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 4)
                }

            } compactLeading: {
                Image(systemName: context.state.isWork ? "brain.head.profile" : "cup.and.saucer")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 40)
            } minimal: {
                Image(systemName: context.state.isWork ? "timer" : "cup.and.saucer")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension TallyvityAttributes {
    fileprivate static var preview: TallyvityAttributes {
        TallyvityAttributes(goal: "Write the proposal", totalLoops: 4)
    }
}

extension TallyvityAttributes.ContentState {
    fileprivate static var working: TallyvityAttributes.ContentState {
        TallyvityAttributes.ContentState(endDate: Date().addingTimeInterval(1200), isWork: true, loopNumber: 2)
    }

    fileprivate static var onBreak: TallyvityAttributes.ContentState {
        TallyvityAttributes.ContentState(endDate: Date().addingTimeInterval(300), isWork: false, loopNumber: 2)
    }
}

#Preview("Notification", as: .content, using: TallyvityAttributes.preview) {
    TallyvityWidgetLiveActivity()
} contentStates: {
    TallyvityAttributes.ContentState.working
    TallyvityAttributes.ContentState.onBreak
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: TallyvityAttributes.preview) {
    TallyvityWidgetLiveActivity()
} contentStates: {
    TallyvityAttributes.ContentState.working
    TallyvityAttributes.ContentState.onBreak
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: TallyvityAttributes.preview) {
    TallyvityWidgetLiveActivity()
} contentStates: {
    TallyvityAttributes.ContentState.working
    TallyvityAttributes.ContentState.onBreak
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: TallyvityAttributes.preview) {
    TallyvityWidgetLiveActivity()
} contentStates: {
    TallyvityAttributes.ContentState.working
    TallyvityAttributes.ContentState.onBreak
}
