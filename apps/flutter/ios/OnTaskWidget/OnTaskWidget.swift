import WidgetKit
import SwiftUI

// MARK: — Widget Data Model
// Read from App Group UserDefaults — NO network calls allowed in WidgetKit.
struct OnTaskWidgetEntry: TimelineEntry {
    let date: Date
    let activeTaskTitle: String?
    let activeElapsedSeconds: Int?
    let nextTaskTitle: String?
    let nextTaskTime: String?
    let scheduleHealth: ScheduleHealth
    let todayTasks: [TodayTask]
}

enum ScheduleHealth: String {
    case healthy, atRisk = "at_risk", critical
    var colour: Color {
        switch self {
        case .healthy:  return Color(red: 107/255, green: 158/255, blue: 120/255)  // Sage #6B9E78
        case .atRisk:   return Color(red: 201/255, green: 138/255, blue: 46/255)   // Amber #C98A2E
        case .critical: return Color(red: 196/255, green: 98/255,  blue: 58/255)   // Terracotta #C4623A
        }
    }
    var icon: String {
        switch self {
        case .healthy:  return "checkmark.circle"
        case .atRisk:   return "exclamationmark.triangle"
        case .critical: return "exclamationmark.circle"
        }
    }
    var label: String {
        switch self {
        case .healthy:  return "On track"
        case .atRisk:   return "Running tight"
        case .critical: return "Overbooked"
        }
    }
}

struct TodayTask: Codable, Identifiable {
    let title: String
    let scheduledTime: String
    let listName: String
    var id: String { "\(title)_\(scheduledTime)" }
}

// MARK: — Timeline Provider
// Reads App Group UserDefaults. No network calls.
struct OnTaskTimelineProvider: TimelineProvider {
    typealias Entry = OnTaskWidgetEntry

    func placeholder(in context: Context) -> OnTaskWidgetEntry {
        OnTaskWidgetEntry(
            date: Date(),
            activeTaskTitle: "Pay rent",
            activeElapsedSeconds: 342,
            nextTaskTitle: nil,
            nextTaskTime: nil,
            scheduleHealth: .healthy,
            todayTasks: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (OnTaskWidgetEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OnTaskWidgetEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every 15 minutes.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func readEntry() -> OnTaskWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.ontaskhq.ontask")
        let healthRaw = defaults?.string(forKey: "widget_schedule_health") ?? "healthy"
        let health = ScheduleHealth(rawValue: healthRaw) ?? .healthy

        var todayTasks: [TodayTask] = []
        if let jsonString = defaults?.string(forKey: "widget_today_tasks"),
           let jsonData = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([TodayTask].self, from: jsonData) {
            todayTasks = Array(decoded.prefix(3))
        }

        return OnTaskWidgetEntry(
            date: Date(),
            activeTaskTitle: defaults?.string(forKey: "widget_active_task_title"),
            activeElapsedSeconds: defaults?.object(forKey: "widget_active_elapsed_sec") as? Int,
            nextTaskTitle: defaults?.string(forKey: "widget_next_task_title"),
            nextTaskTime: defaults?.string(forKey: "widget_next_task_time"),
            scheduleHealth: health,
            todayTasks: todayTasks
        )
    }
}

// MARK: — Widget Definitions

struct OnTaskNowWidget: Widget {
    let kind: String = "OnTaskNowWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OnTaskTimelineProvider()) { entry in
            NowWidgetView(entry: entry)
        }
        .configurationDisplayName("Now")
        .description("See your current task at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct OnTaskTodayWidget: Widget {
    let kind: String = "OnTaskTodayWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OnTaskTimelineProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Your next tasks and today's schedule health.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: — Widget Bundle Entry Point
@main
struct OnTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        OnTaskNowWidget()
        OnTaskTodayWidget()
    }
}
