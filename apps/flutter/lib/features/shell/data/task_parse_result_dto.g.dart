// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_parse_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskParseResultDto _$TaskParseResultDtoFromJson(Map<String, dynamic> json) =>
    _TaskParseResultDto(
      title: json['title'] as String,
      confidence: json['confidence'] as String,
      dueDate: json['dueDate'] as String?,
      scheduledTime: json['scheduledTime'] as String?,
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)
          ?.toInt(),
      energyRequirement: json['energyRequirement'] as String?,
      listId: json['listId'] as String?,
      fieldConfidences:
          (json['fieldConfidences'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$TaskParseResultDtoToJson(_TaskParseResultDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'confidence': instance.confidence,
      'dueDate': instance.dueDate,
      'scheduledTime': instance.scheduledTime,
      'estimatedDurationMinutes': instance.estimatedDurationMinutes,
      'energyRequirement': instance.energyRequirement,
      'listId': instance.listId,
      'fieldConfidences': instance.fieldConfidences,
    };
