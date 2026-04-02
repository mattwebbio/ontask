import SwiftUI
import WidgetKit

// MARK: — Now Widget (small)
// Shows: active task + elapsed timer OR next scheduled task + time
// ElapsedTimerView is imported from SharedWidgetViews/ — DO NOT redeclare here.
struct NowWidgetView: View {
    let entry: OnTaskWidgetEntry

    var body: some View {
        ZStack {
            Color(.systemBackground)
            if let taskTitle = entry.activeTaskTitle {
                // Active task state
                VStack(alignment: .leading, spacing: 6) {
                    Label("Now", systemImage: "timer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(taskTitle)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .lineLimit(2)
                    if let elapsed = entry.activeElapsedSeconds {
                        ElapsedTimerView(elapsedSeconds: elapsed, maxSeconds: 3600)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let nextTitle = entry.nextTaskTitle {
                // Next task state
                VStack(alignment: .leading, spacing: 6) {
                    Label("Next", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(nextTitle)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .lineLimit(2)
                    if let time = entry.nextTaskTime {
                        Text(formattedTime(iso: time))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                // Empty state
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("All clear")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .widgetBackground(Color(.systemBackground))
    }

    private func formattedTime(iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.timeStyle = .short
        display.dateStyle = .none
        return display.string(from: date)
    }
}

// MARK: — Today Widget (medium)
// Shows: next 3 scheduled tasks + schedule health strip
struct TodayWidgetView: View {
    let entry: OnTaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Schedule Health Strip (top)
            scheduleHealthStrip
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            // Task rows
            if entry.todayTasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No tasks scheduled today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(Array(entry.todayTasks.prefix(3))) { task in
                    TodayTaskRow(task: task)
                }
            }
            Spacer(minLength: 0)
        }
        .widgetBackground(Color(.systemBackground))
    }

    private var scheduleHealthStrip: some View {
        HStack(spacing: 4) {
            // Icon + label required — never colour alone (NFR-A4 colour-blind accessibility)
            Image(systemName: entry.scheduleHealth.icon)
                .font(.caption2)
                .foregroundColor(entry.scheduleHealth.colour)
            Text(entry.scheduleHealth.label)
                .font(.caption2.weight(.medium))
                .foregroundColor(entry.scheduleHealth.colour)
            Spacer()
            Text("Today")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TodayTaskRow: View {
    let task: TodayTask

    var body: some View {
        HStack(spacing: 8) {
            Text(task.scheduledTime)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 38, alignment: .trailing)
            Text(task.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            Spacer()
            Text(task.listName)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: — widgetBackground compatibility shim
// WidgetKit requires .containerBackground on iOS 17+; widgetBackground is a helper.
extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}
