// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guided_chat_task_draft_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuidedChatTaskDraftDto _$GuidedChatTaskDraftDtoFromJson(
  Map<String, dynamic> json,
) => _GuidedChatTaskDraftDto(
  title: json['title'] as String?,
  dueDate: json['dueDate'] as String?,
  scheduledTime: json['scheduledTime'] as String?,
  estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)?.toInt(),
  energyRequirement: json['energyRequirement'] as String?,
  listId: json['listId'] as String?,
);

Map<String, dynamic> _$GuidedChatTaskDraftDtoToJson(
  _GuidedChatTaskDraftDto instance,
) => <String, dynamic>{
  'title': instance.title,
  'dueDate': instance.dueDate,
  'scheduledTime': instance.scheduledTime,
  'estimatedDurationMinutes': instance.estimatedDurationMinutes,
  'energyRequirement': instance.energyRequirement,
  'listId': instance.listId,
};
