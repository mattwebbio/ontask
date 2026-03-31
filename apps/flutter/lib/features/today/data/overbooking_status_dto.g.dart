// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overbooking_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OverbookedTaskDto _$OverbookedTaskDtoFromJson(Map<String, dynamic> json) =>
    _OverbookedTaskDto(
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      hasStake: json['hasStake'] as bool,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$OverbookedTaskDtoToJson(_OverbookedTaskDto instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'taskTitle': instance.taskTitle,
      'hasStake': instance.hasStake,
      'durationMinutes': instance.durationMinutes,
    };

_OverbookingStatusDto _$OverbookingStatusDtoFromJson(
  Map<String, dynamic> json,
) => _OverbookingStatusDto(
  isOverbooked: json['isOverbooked'] as bool,
  severity: json['severity'] as String,
  capacityPercent: (json['capacityPercent'] as num).toDouble(),
  overbookedTasks: (json['overbookedTasks'] as List<dynamic>)
      .map((e) => OverbookedTaskDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OverbookingStatusDtoToJson(
  _OverbookingStatusDto instance,
) => <String, dynamic>{
  'isOverbooked': instance.isOverbooked,
  'severity': instance.severity,
  'capacityPercent': instance.capacityPercent,
  'overbookedTasks': instance.overbookedTasks,
};
