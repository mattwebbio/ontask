import ActivityKit
import WidgetKit
import SwiftUI

// MARK: — Lock Screen Live Activity View

struct TaskTimerLockScreenView: View {
    let context: ActivityViewContext<OnTaskActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.taskTitle)
                    .font(.headline)
                    .lineLimit(1)
                if let elapsed = context.state.elapsedSeconds {
                    Text(formatElapsed(elapsed))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let elapsed = context.state.elapsedSeconds {
                ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                    .frame(width: 44, height: 44)
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
    }

    private func formatElapsed(_ s: Int) -> String {
        let h = s / 3600; let m = (s % 3600) / 60; let sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }
}

struct CommitmentCountdownLockScreenView: View {
    let context: ActivityViewContext<OnTaskActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.taskTitle)
                    .font(.headline)
                    .lineLimit(1)
                // Neutral tone per UX copy rules — never urgency language
                if let deadline = context.state.deadlineTimestamp {
                    Text(deadline, style: .relative)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                if let amount = context.state.stakeAmount {
                    Text("$\(amount) at stake")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let deadline = context.state.deadlineTimestamp {
                CountdownArcView(
                    deadlineTimestamp: deadline,
                    stakeAmount: context.state.stakeAmount
                )
                .frame(width: 44, height: 44)
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
    }
}

// MARK: — Widget Configuration

struct OnTaskLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OnTaskActivityAttributes.self) { context in
            // Lock Screen — branch on activity type via elapsedSeconds presence
            if context.state.elapsedSeconds != nil {
                TaskTimerLockScreenView(context: context)
            } else {
                CommitmentCountdownLockScreenView(context: context)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.taskTitle)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let elapsed = context.state.elapsedSeconds {
                        ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                            .frame(width: 36, height: 36)
                    } else if let deadline = context.state.deadlineTimestamp {
                        CountdownArcView(
                            deadlineTimestamp: deadline,
                            stakeAmount: context.state.stakeAmount
                        )
                        .frame(width: 36, height: 36)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        // Done button — triggers task completion via deep link
                        // Note: Link with ontask:// URL scheme requires iOS 17.0+.
                        // Wrapped in availability check per Dev Notes.
                        if #available(iOS 17.0, *) {
                            Link(destination: URL(string: "ontask://task/done?taskId=\(context.attributes.taskId)")!) {
                                Label("Done", systemImage: "checkmark.circle.fill")
                                    .font(.callout.bold())
                            }
                            if context.state.elapsedSeconds != nil {
                                // Pause — only shown for task_timer
                                Link(destination: URL(string: "ontask://task/pause?taskId=\(context.attributes.taskId)")!) {
                                    Label("Pause", systemImage: "pause.circle")
                                        .font(.callout)
                                }
                            } else {
                                // Watch Mode — only shown for commitment_countdown
                                Link(destination: URL(string: "ontask://task/watchmode?taskId=\(context.attributes.taskId)")!) {
                                    Label("Watch Mode", systemImage: "eye.circle")
                                        .font(.callout)
                                }
                            }
                        }
                    }
                }
            } compactLeading: {
                // Compact leading: task name truncated
                Text(context.state.taskTitle)
                    .font(.caption2)
                    .lineLimit(1)
            } compactTrailing: {
                // Compact trailing: arc timer or countdown arc
                if let elapsed = context.state.elapsedSeconds {
                    ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                        .frame(width: 20, height: 20)
                } else if let deadline = context.state.deadlineTimestamp {
                    CountdownArcView(deadlineTimestamp: deadline, stakeAmount: nil)
                        .frame(width: 20, height: 20)
                }
            } minimal: {
                // Minimal: arc indicator only
                if let elapsed = context.state.elapsedSeconds {
                    ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                        .frame(width: 14, height: 14)
                } else if let deadline = context.state.deadlineTimestamp {
                    CountdownArcView(deadlineTimestamp: deadline, stakeAmount: nil)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                }
            }
        }
    }
}
