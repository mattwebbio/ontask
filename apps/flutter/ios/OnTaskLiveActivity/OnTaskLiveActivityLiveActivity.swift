import ActivityKit
import UIKit
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

// MARK: — Watch Mode Lock Screen View

struct WatchModeLockScreenView: View {
    let context: ActivityViewContext<OnTaskActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Watch Mode active")
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.taskTitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let elapsed = context.state.elapsedSeconds {
                    Text(formatElapsed(elapsed))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            // Camera indicator: system icon to signal active monitoring.
            // Red camera.fill icon — visible, privacy-transparent.
            Image(systemName: "camera.fill")
                .foregroundColor(.red)
                .font(.title2)
                .accessibilityLabel("Camera active")
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

// MARK: — VoiceOver Announcements (UX-DR24)

/// Posts a VoiceOver announcement from the Swift Live Activity extension.
///
/// Must be called from Swift — Flutter cannot post UIAccessibility notifications
/// across the extension boundary (architecture constraint, ARCH-28).
///
/// Three announcement triggers (per epic acceptance criteria):
/// 1. Activity started — posted when activityStatus transitions to .active or .watchMode
/// 2. 30-minute session milestone — posted when elapsedSeconds crosses 1800
/// 3. Deadline approaching — posted when deadlineTimestamp is within 30 minutes
func postVoiceOverAnnouncement(_ message: String) {
    UIAccessibility.post(notification: .announcement, argument: message)
}

// MARK: — Widget Configuration

struct OnTaskLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OnTaskActivityAttributes.self) { context in
            // Lock Screen — branch on activityStatus to distinguish watch_mode
            // from task_timer (both have elapsedSeconds set).
            Group {
                switch context.state.activityStatus {
                case .watchMode:
                    WatchModeLockScreenView(context: context)
                case .active where context.state.elapsedSeconds != nil:
                    TaskTimerLockScreenView(context: context)
                default:
                    CommitmentCountdownLockScreenView(context: context)
                }
            }
            .onChange(of: context.state.activityStatus) { newStatus in
                switch newStatus {
                case .active:
                    postVoiceOverAnnouncement("Task timer started. \(context.state.taskTitle)")
                case .watchMode:
                    postVoiceOverAnnouncement("Watch Mode started. \(context.state.taskTitle)")
                case .completed:
                    postVoiceOverAnnouncement("Task completed. \(context.state.taskTitle)")
                case .failed:
                    postVoiceOverAnnouncement("Task deadline passed. \(context.state.taskTitle)")
                }
            }
            .onChange(of: context.state.elapsedSeconds) { newElapsed in
                // 30-minute session milestone (AC: 2)
                if let elapsed = newElapsed, elapsed == 1800 {
                    postVoiceOverAnnouncement("30 minutes in. Keep going.")
                }
            }
            .onChange(of: context.state.deadlineTimestamp) { _ in
                // Deadline approaching — within 30 minutes (AC: 2)
                if let deadline = context.state.deadlineTimestamp {
                    let remaining = deadline.timeIntervalSinceNow
                    if remaining > 0 && remaining <= 1800 {
                        let minutes = Int(remaining / 60)
                        postVoiceOverAnnouncement("\(minutes) minutes until deadline. \(context.state.taskTitle)")
                    }
                }
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.activityStatus == .watchMode {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Watch Mode active")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                            Text(context.state.taskTitle)
                                .font(.headline)
                                .lineLimit(1)
                        }
                    } else {
                        Text(context.state.taskTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }
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
                        if #available(iOS 17.0, *) {
                            if context.state.activityStatus == .watchMode {
                                // End Session — terminates Watch Mode session via deep link
                                Link(destination: URL(string: "ontask://watchmode/end?taskId=\(context.attributes.taskId)")!) {
                                    Label("End Session", systemImage: "stop.circle.fill")
                                        .font(.callout.bold())
                                        .foregroundColor(.red)
                                }
                            } else {
                                // Done button
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
                }
            } compactLeading: {
                if context.state.activityStatus == .watchMode {
                    // Camera indicator — red camera icon (UX-DR25: compact = camera indicator + session timer)
                    Image(systemName: "camera.fill")
                        .foregroundColor(.red)
                        .font(.caption2)
                } else {
                    // Compact leading: task name truncated
                    Text(context.state.taskTitle)
                        .font(.caption2)
                        .lineLimit(1)
                }
            } compactTrailing: {
                if context.state.activityStatus == .watchMode,
                   let elapsed = context.state.elapsedSeconds {
                    // Session timer in compact trailing (UX-DR25: camera indicator + session timer)
                    ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                        .frame(width: 20, height: 20)
                } else if let elapsed = context.state.elapsedSeconds {
                    ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                        .frame(width: 20, height: 20)
                } else if let deadline = context.state.deadlineTimestamp {
                    CountdownArcView(deadlineTimestamp: deadline, stakeAmount: nil)
                        .frame(width: 20, height: 20)
                }
            } minimal: {
                if context.state.activityStatus == .watchMode {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.red)
                        .font(.caption2)
                } else if let elapsed = context.state.elapsedSeconds {
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
