import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_parse_result.freezed.dart';

/// Domain model for the result of parsing a natural language task utterance.
///
/// Returned by [NlpTaskRepository.parseUtterance] after calling
/// `POST /v1/tasks/parse` (FR1b).
///
/// Fields with 'low' confidence in [fieldConfidences] are displayed with
/// a dashed border in the UI (UX-DR29), signalling the user should review them.
@freezed
abstract class TaskParseResult with _$TaskParseResult {
  const factory TaskParseResult({
    /// The parsed task title.
    required String title,

    /// Overall confidence in the parse result.
    /// 'low' when the utterance was too ambiguous.
    required String confidence,

    /// Resolved due date as ISO 8601 string, if mentioned.
    String? dueDate,

    /// Resolved scheduled time as ISO 8601 string, if mentioned.
    String? scheduledTime,

    /// Estimated duration in minutes, if mentioned.
    int? estimatedDurationMinutes,

    /// Energy requirement (high_focus / low_energy / flexible), if inferred.
    String? energyRequirement,

    /// Matched list ID from the user's lists, if mentioned.
    String? listId,

    /// Per-field confidence map (field name → 'high' | 'low').
    /// Used by the UI to render dashed borders on uncertain fields.
    @Default({}) Map<String, String> fieldConfidences,
  }) = _TaskParseResult;
}
