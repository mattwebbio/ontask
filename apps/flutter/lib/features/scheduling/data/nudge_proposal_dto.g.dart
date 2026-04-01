// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nudge_proposal_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NudgeProposalDto _$NudgeProposalDtoFromJson(Map<String, dynamic> json) =>
    _NudgeProposalDto(
      taskId: json['taskId'] as String,
      proposedStartTime: json['proposedStartTime'] as String,
      proposedEndTime: json['proposedEndTime'] as String,
      interpretation: json['interpretation'] as String,
      confidence: json['confidence'] as String,
    );

Map<String, dynamic> _$NudgeProposalDtoToJson(_NudgeProposalDto instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'proposedStartTime': instance.proposedStartTime,
      'proposedEndTime': instance.proposedEndTime,
      'interpretation': instance.interpretation,
      'confidence': instance.confidence,
    };
