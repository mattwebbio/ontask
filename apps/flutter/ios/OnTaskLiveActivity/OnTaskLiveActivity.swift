import ActivityKit
import WidgetKit
import SwiftUI

// MARK: — ActivityAttributes Definition
// Payload stays within the 4KB ActivityKit limit.
// Only include: task title, time values, stake amount, status flag.
// No proof content, no notes.
struct OnTaskActivityAttributes: ActivityAttributes {
    let taskId: String

    struct ContentState: Codable, Hashable {
        var taskTitle: String
        var elapsedSeconds: Int?       // nil when not in timer mode
        var deadlineTimestamp: Date?   // nil when no commitment deadline
        var stakeAmount: Decimal?      // nil when no stake
        var activityStatus: Status

        enum Status: String, Codable {
            case active, completed, failed, watchMode
        }
    }
}

// MARK: — Widget Bundle Entry Point
@main
struct OnTaskLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        OnTaskLiveActivityWidget()
    }
}

// MARK: — Live Activity Widget
// UI implementation (Dynamic Island + Lock Screen views) is in Story 12.2.
// This story only scaffolds the extension with the attributes definition.
// Provide a minimal placeholder widget body so the target compiles.
struct OnTaskLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OnTaskActivityAttributes.self) { context in
            // Lock Screen UI — Story 12.2 implements this.
            // Placeholder: show task title text.
            Text(context.state.taskTitle)
                .padding()
        } dynamicIsland: { context in
            // Dynamic Island UI — Story 12.2 implements this.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.taskTitle)
                }
            } compactLeading: {
                Text(context.state.taskTitle)
                    .font(.caption2)
                    .lineLimit(1)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}
