import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tasks/domain/energy_requirement.dart';
import '../../tasks/domain/recurrence_rule.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_priority.dart';
import '../../tasks/domain/time_window.dart';

part 'search_result.freezed.dart';

/// A search result extends [Task] with list context for display.
@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
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
    DateTime? archivedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? durationMinutes,
    DateTime? scheduledStartTime,
    // Search-specific enrichment
    String? listName,
  }) = _SearchResult;

  /// Creates a [SearchResult] from an existing [Task] with optional list context.
  factory SearchResult.fromTask(Task task, String? listName) => SearchResult(
        id: task.id,
        title: task.title,
        notes: task.notes,
        dueDate: task.dueDate,
        listId: task.listId,
        sectionId: task.sectionId,
        parentTaskId: task.parentTaskId,
        position: task.position,
        timeWindow: task.timeWindow,
        timeWindowStart: task.timeWindowStart,
        timeWindowEnd: task.timeWindowEnd,
        energyRequirement: task.energyRequirement,
        priority: task.priority,
        recurrenceRule: task.recurrenceRule,
        recurrenceInterval: task.recurrenceInterval,
        recurrenceDaysOfWeek: task.recurrenceDaysOfWeek,
        recurrenceParentId: task.recurrenceParentId,
        archivedAt: task.archivedAt,
        completedAt: task.completedAt,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        durationMinutes: task.durationMinutes,
        scheduledStartTime: task.scheduledStartTime,
        listName: listName,
      );
}
