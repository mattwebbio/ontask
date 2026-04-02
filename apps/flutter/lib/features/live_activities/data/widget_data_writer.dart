import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'widget_data_writer.g.dart';

/// Writes task snapshot data to the shared App Group UserDefaults for WidgetKit consumption.
///
/// WidgetKit extensions CANNOT make network calls — they read from App Group shared storage.
/// This class is the Flutter side of the data bridge.
/// iOS only — all calls are guarded with defaultTargetPlatform != TargetPlatform.iOS.
class WidgetDataWriter {
  static const _channel = MethodChannel('com.ontaskhq.ontask/widget_data');

  /// Writes the current task state snapshot for widget display.
  /// Call this whenever task state changes (task started, completed, rescheduled).
  Future<void> writeWidgetData({
    String? activeTaskTitle,
    int? activeElapsedSeconds,
    String? nextTaskTitle,
    String? nextTaskTimeIso, // ISO 8601
    required String scheduleHealth, // "healthy" | "at_risk" | "critical"
    required List<Map<String, String>> todayTasks, // max 3 items
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _channel.invokeMethod<void>('writeWidgetData', {
      'activeTaskTitle': activeTaskTitle,
      'activeElapsedSeconds': activeElapsedSeconds,
      'nextTaskTitle': nextTaskTitle,
      'nextTaskTimeIso': nextTaskTimeIso,
      'scheduleHealth': scheduleHealth,
      'todayTasks': todayTasks,
    });
  }

  /// Triggers WidgetKit to reload both widget timelines.
  /// Call after writeWidgetData() to force immediate refresh.
  Future<void> reloadWidgets() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _channel.invokeMethod<void>('reloadWidgets');
  }
}

@riverpod
WidgetDataWriter widgetDataWriter(Ref ref) {
  return WidgetDataWriter();
}
