import 'package:freezed_annotation/freezed_annotation.dart';

part 'overbooking_status.freezed.dart';

/// Severity level of the overbooking condition.
enum OverbookingSeverity { none, atRisk, critical }

/// A single task that contributes to the overbooking condition.
@freezed
abstract class OverbookedTask with _$OverbookedTask {
  const factory OverbookedTask({
    required String taskId,
    required String taskTitle,
    required bool hasStake,
    required int durationMinutes,
  }) = _OverbookedTask;
}

/// Describes whether today's schedule is overbooked and to what degree.
@freezed
abstract class OverbookingStatus with _$OverbookingStatus {
  const factory OverbookingStatus({
    required bool isOverbooked,
    required OverbookingSeverity severity,
    required double capacityPercent,
    required List<OverbookedTask> overbookedTasks,
  }) = _OverbookingStatus;
}
