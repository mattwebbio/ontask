// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_explanation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleExplanationDto _$ScheduleExplanationDtoFromJson(
  Map<String, dynamic> json,
) => _ScheduleExplanationDto(
  reasons: (json['reasons'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ScheduleExplanationDtoToJson(
  _ScheduleExplanationDto instance,
) => <String, dynamic>{'reasons': instance.reasons};
