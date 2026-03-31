import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

import '../domain/energy_requirement.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_priority.dart';
import '../domain/time_window.dart';

part 'task_dto.freezed.dart';
part 'task_dto.g.dart';

/// Data transfer object for the `/v1/tasks` API response.
///
/// Handles JSON serialisation and maps to the [Task] domain model via [toDomain].
@freezed
abstract class TaskDto with _$TaskDto {
  const TaskDto._();

  const factory TaskDto({
    required String id,
    required String title,
    String? notes,
    String? dueDate,
    String? listId,
    String? sectionId,
    String? parentTaskId,
    required int position,
    String? timeWindow,
    String? timeWindowStart,
    String? timeWindowEnd,
    String? energyRequirement,
    String? priority,
    String? recurrenceRule,
    int? recurrenceInterval,
    String? recurrenceDaysOfWeek,
    String? recurrenceParentId,
    String? archivedAt,
    String? completedAt,
    required String createdAt,
    required String updatedAt,
  }) = _TaskDto;

  factory TaskDto.fromJson(Map<String, dynamic> json) => _$TaskDtoFromJson(json);

  /// Converts this DTO to a [Task] domain model.
  Task toDomain() => Task(
        id: id,
        title: title,
        notes: notes,
        dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
        listId: listId,
        sectionId: sectionId,
        parentTaskId: parentTaskId,
        position: position,
        timeWindow: TimeWindow.fromJson(timeWindow),
        timeWindowStart: timeWindowStart,
        timeWindowEnd: timeWindowEnd,
        energyRequirement: EnergyRequirement.fromJson(energyRequirement),
        priority: TaskPriority.fromJson(priority),
        recurrenceRule: RecurrenceRule.fromJson(recurrenceRule),
        recurrenceInterval: recurrenceInterval,
        recurrenceDaysOfWeek: recurrenceDaysOfWeek != null
            ? (jsonDecode(recurrenceDaysOfWeek!) as List).cast<int>()
            : null,
        recurrenceParentId: recurrenceParentId,
        archivedAt: archivedAt != null ? DateTime.parse(archivedAt!) : null,
        completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
