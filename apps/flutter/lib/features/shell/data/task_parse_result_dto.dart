import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/task_parse_result.dart';

part 'task_parse_result_dto.freezed.dart';
part 'task_parse_result_dto.g.dart';

/// Data transfer object for the task parse result returned by
/// `POST /v1/tasks/parse` (FR1b).
///
/// The API response wraps this in a `{ data: ... }` envelope.
/// Maps to the [TaskParseResult] domain model via [toDomain].
@freezed
abstract class TaskParseResultDto with _$TaskParseResultDto {
  const TaskParseResultDto._();

  const factory TaskParseResultDto({
    required String title,
    required String confidence,
    String? dueDate,
    String? scheduledTime,
    int? estimatedDurationMinutes,
    String? energyRequirement,
    String? listId,
    @Default(<String, String>{}) Map<String, String> fieldConfidences,
  }) = _TaskParseResultDto;

  factory TaskParseResultDto.fromJson(Map<String, dynamic> json) =>
      _$TaskParseResultDtoFromJson(json);

  /// Converts this DTO to a [TaskParseResult] domain model.
  TaskParseResult toDomain() => TaskParseResult(
        title: title,
        confidence: confidence,
        dueDate: dueDate,
        scheduledTime: scheduledTime,
        estimatedDurationMinutes: estimatedDurationMinutes,
        energyRequirement: energyRequirement,
        listId: listId,
        fieldConfidences: fieldConfidences,
      );
}
