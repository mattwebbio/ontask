import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

import '../../tasks/domain/energy_requirement.dart';
import '../../tasks/domain/recurrence_rule.dart';
import '../../tasks/domain/task_priority.dart';
import '../../tasks/domain/time_window.dart';
import '../domain/search_result.dart';

part 'search_result_dto.freezed.dart';
part 'search_result_dto.g.dart';

/// DTO for search API response items.
///
/// Extends the standard task fields with [listName] for search result display.
@freezed
abstract class SearchResultDto with _$SearchResultDto {
  const SearchResultDto._();

  const factory SearchResultDto({
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
    // Search-specific enrichment
    String? listName,
  }) = _SearchResultDto;

  factory SearchResultDto.fromJson(Map<String, dynamic> json) =>
      _$SearchResultDtoFromJson(json);

  /// Converts this DTO to a [SearchResult] domain model.
  SearchResult toDomain() => SearchResult(
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
        recurrenceDaysOfWeek: _parseDaysOfWeek(recurrenceDaysOfWeek),
        recurrenceParentId: recurrenceParentId,
        archivedAt: archivedAt != null ? DateTime.parse(archivedAt!) : null,
        completedAt:
            completedAt != null ? DateTime.parse(completedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        listName: listName,
      );

  static List<int>? _parseDaysOfWeek(String? value) {
    if (value == null) return null;
    try {
      return (jsonDecode(value) as List).cast<int>();
    } catch (_) {
      return null;
    }
  }
}
