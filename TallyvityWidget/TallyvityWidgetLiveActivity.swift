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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GOAL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text(context.attributes.goal)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    .padding(.leading, 12)
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.isWork ? "FOCUS" : "BREAK")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(context.state.isWork ? .orange : .cyan)
                        
                        HStack(spacing: 6) {
                            Image(systemName: context.state.isWork ? "brain.head.profile" : "cup.and.saucer")
                                .foregroundStyle(context.state.isWork ? .orange : .cyan)
                            Text(context.state.endDate, style: .timer)
                                .font(.title3.weight(.bold).monospacedDigit())
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Spacer()
                        Text("Loop \(context.state.loopNumber) of \(context.attributes.totalLoops)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

            } compactLeading: {
                Image(systemName: context.state.isWork ? "brain.head.profile" : "cup.and.saucer")
                    .foregroundStyle(context.state.isWork ? .orange : .cyan)
                    .font(.caption2.weight(.bold))
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(context.state.isWork ? .orange : .cyan)
                    .frame(minWidth: 32)
            } minimal: {
                Image(systemName: context.state.isWork ? "brain.head.profile" : "cup.and.saucer")
                    .foregroundStyle(context.state.isWork ? .orange : .cyan)
                    .font(.caption2.weight(.bold))
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
