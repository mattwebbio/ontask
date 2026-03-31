import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_change.freezed.dart';

/// Describes whether a task was moved to a new time or removed from the schedule.
enum ScheduleChangeType { moved, removed }

/// Represents a single task change event in the schedule diff.
@freezed
abstract class ScheduleChangeItem with _$ScheduleChangeItem {
  const factory ScheduleChangeItem({
    required String taskId,
    required String taskTitle,
    required ScheduleChangeType changeType,
    required DateTime? oldTime,
    required DateTime? newTime,
  }) = _ScheduleChangeItem;
}

/// Contains the full schedule diff returned by the API.
@freezed
abstract class ScheduleChanges with _$ScheduleChanges {
  const factory ScheduleChanges({
    required bool hasMeaningfulChanges,
    required int changeCount,
    required List<ScheduleChangeItem> changes,
  }) = _ScheduleChanges;
}
