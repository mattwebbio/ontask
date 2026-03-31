import 'package:freezed_annotation/freezed_annotation.dart';

import 'energy_requirement.dart';
import 'task_priority.dart';
import 'time_window.dart';

part 'task.freezed.dart';

/// Core task domain model.
///
/// Maps to the `tasks` table and the `/v1/tasks` API response.
/// Timestamps use nullable [DateTime] — null means "not set / not applicable".
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? notes,
    DateTime? dueDate,
    String? listId,
    String? sectionId,
    String? parentTaskId,
    required int position,
    TimeWindow? timeWindow,
    String? timeWindowStart,
    String? timeWindowEnd,
    EnergyRequirement? energyRequirement,
    @Default(TaskPriority.normal) TaskPriority? priority,
    DateTime? archivedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}
