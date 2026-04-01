import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/nudge_proposal.dart';

part 'nudge_proposal_dto.freezed.dart';
part 'nudge_proposal_dto.g.dart';

/// Data transfer object for the nudge proposal returned by
/// `POST /v1/tasks/:id/schedule/nudge` (FR14).
///
/// Maps the `data` sub-object from the API response to the [NudgeProposal]
/// domain model via [toDomain].
@freezed
abstract class NudgeProposalDto with _$NudgeProposalDto {
  const NudgeProposalDto._();

  const factory NudgeProposalDto({
    required String taskId,
    required String proposedStartTime,
    required String proposedEndTime,
    required String interpretation,
    required String confidence,
  }) = _NudgeProposalDto;

  factory NudgeProposalDto.fromJson(Map<String, dynamic> json) =>
      _$NudgeProposalDtoFromJson(json);

  /// Converts this DTO to a [NudgeProposal] domain model.
  NudgeProposal toDomain() => NudgeProposal(
        taskId: taskId,
        proposedStartTime: DateTime.parse(proposedStartTime),
        proposedEndTime: DateTime.parse(proposedEndTime),
        interpretation: interpretation,
        confidence: confidence,
      );
}
