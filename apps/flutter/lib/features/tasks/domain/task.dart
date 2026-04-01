import 'package:freezed_annotation/freezed_annotation.dart';

import '../../now/domain/proof_mode.dart';
import 'energy_requirement.dart';
import 'recurrence_rule.dart';
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
    RecurrenceRule? recurrenceRule,
    int? recurrenceInterval,
    List<int>? recurrenceDaysOfWeek,
    String? recurrenceParentId,
    DateTime? startedAt,
    int? elapsedSeconds,
    DateTime? archivedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? durationMinutes,
    DateTime? scheduledStartTime,
    String? assignedToUserId,
    String? listName,
    // Proof mode for this task (FR20). Defaults to standard (no proof required).
    @Default(ProofMode.standard) ProofMode proofMode,
    // True when this task has a user-set proof mode override (differs from list/section default).
    @Default(false) bool proofModeIsCustom,
    // Proof visibility fields (FR21, Story 5.5)
    // URL to the proof media (photo/video/doc) — null when no retained proof.
    String? proofMediaUrl,
    // True when the user chose "Keep as completion record" (FR38, Story 7.7).
    @Default(false) bool proofRetained,
    // Display name of the member who completed this task; null when incomplete or unknown.
    String? completedByName,
  }) = _Task;
}
