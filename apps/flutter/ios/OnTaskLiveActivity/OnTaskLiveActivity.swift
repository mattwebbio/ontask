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
// Full Live Activity UI (Dynamic Island + Lock Screen views) is in
// OnTaskLiveActivityLiveActivity.swift (Story 12.2).
@main
struct OnTaskLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        OnTaskLiveActivityWidget()
    }
}
