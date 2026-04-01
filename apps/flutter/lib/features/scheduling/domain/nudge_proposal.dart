import 'package:freezed_annotation/freezed_annotation.dart';

part 'nudge_proposal.freezed.dart';

/// Domain model representing a proposed schedule change from the AI nudge endpoint.
///
/// Returned by `POST /v1/tasks/:id/schedule/nudge` (FR14).
/// This is a PROPOSAL only — it has not been applied to the schedule.
/// Call [SchedulingRepository.confirmNudge] to commit the change.
@freezed
abstract class NudgeProposal with _$NudgeProposal {
  const factory NudgeProposal({
    required String taskId,
    required DateTime proposedStartTime,
    required DateTime proposedEndTime,
    required String interpretation,
    required String confidence,
  }) = _NudgeProposal;
}
