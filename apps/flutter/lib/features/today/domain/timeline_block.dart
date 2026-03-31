import 'dart:ui';

import '../../today/presentation/widgets/today_task_row.dart';

/// Data class for timeline hit-test regions.
///
/// This is a domain model for the timeline rendering layer, not an API model.
/// Each block represents a task or calendar event positioned on the timeline.
class TimelineBlock {
  /// Unique task identifier.
  final String taskId;

  /// Display title for the block.
  final String title;

  /// Bounding rectangle for hit testing and rendering.
  Rect bounds;

  /// Scheduled start time for the block.
  final DateTime startTime;

  /// Duration of the block in minutes.
  final int durationMinutes;

  /// Whether this block represents a calendar event (immovable grey block).
  final bool isCalendarEvent;

  /// Visual state for styling (upcoming, current, overdue, completed, calendarEvent).
  final TodayTaskRowState state;

  TimelineBlock({
    required this.taskId,
    required this.title,
    required this.bounds,
    required this.startTime,
    required this.durationMinutes,
    required this.isCalendarEvent,
    required this.state,
  });
}
