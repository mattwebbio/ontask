import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize the Flutter engine first — GeneratedPluginRegistrant and
    // binaryMessenger are only valid after super.application() returns.
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Font detection platform channel.
    // Registered after super.application() so the Flutter engine is fully
    // initialised and binaryMessenger is ready to accept handlers.
    if let controller = window?.rootViewController as? FlutterViewController {
      let fontChannel = FlutterMethodChannel(
        name: "com.ontaskhq.ontask/fonts",
        binaryMessenger: controller.binaryMessenger
      )
      fontChannel.setMethodCallHandler { call, result in
        if call.method == "isNewYorkAvailable" {
          // .NewYorkFont is a private UIFont family available on iOS 13+.
          let families = UIFont.familyNames
          result(families.contains(".NewYorkFont"))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    // If rootViewController is not a FlutterViewController (e.g. unit tests,
    // scene-based lifecycle), the channel is simply not registered and
    // font_channel.dart falls back to Playfair Display gracefully.

    // Widget data platform channel.
    // Writes task snapshot data to App Group UserDefaults for WidgetKit consumption.
    // WidgetKit extensions run in a sandboxed process and CANNOT make network calls —
    // they read from shared UserDefaults. Flutter calls reloadWidgets() after writing
    // to trigger WidgetKit timeline refresh (AC-4, AC-5).
    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(
        name: "com.ontaskhq.ontask/widget_data",
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel.setMethodCallHandler { call, result in
        let defaults = UserDefaults(suiteName: "group.com.ontaskhq.ontask")
        switch call.method {
        case "writeWidgetData":
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
            return
          }
          defaults?.set(args["activeTaskTitle"], forKey: "widget_active_task_title")
          defaults?.set(args["activeElapsedSeconds"], forKey: "widget_active_elapsed_sec")
          defaults?.set(args["nextTaskTitle"], forKey: "widget_next_task_title")
          defaults?.set(args["nextTaskTimeIso"], forKey: "widget_next_task_time")
          defaults?.set(args["scheduleHealth"] as? String ?? "healthy", forKey: "widget_schedule_health")
          if let todayTasks = args["todayTasks"] as? [[String: String]],
             let jsonData = try? JSONSerialization.data(withJSONObject: todayTasks),
             let jsonString = String(data: jsonData, encoding: .utf8) {
            defaults?.set(jsonString, forKey: "widget_today_tasks")
          }
          defaults?.set(Date().timeIntervalSince1970, forKey: "widget_last_updated")
          result(nil)
        case "reloadWidgets":
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "OnTaskNowWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "OnTaskTodayWidget")
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }
}
