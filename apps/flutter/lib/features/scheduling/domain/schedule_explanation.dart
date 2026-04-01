import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_explanation.freezed.dart';

/// Domain model representing a plain-language explanation of why a task
/// was scheduled at its assigned time.
///
/// Populated from the `explanation` field in `GET /v1/tasks/:id/schedule`
/// (FR13). Each reason is a human-readable string — no technical language
/// or variable names (NFR-UX2).
@freezed
abstract class ScheduleExplanation with _$ScheduleExplanation {
  const factory ScheduleExplanation({
    required List<String> reasons,
  }) = _ScheduleExplanation;
}
