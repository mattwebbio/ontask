// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_change_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleChangeItemDto _$ScheduleChangeItemDtoFromJson(
  Map<String, dynamic> json,
) => _ScheduleChangeItemDto(
  taskId: json['taskId'] as String,
  taskTitle: json['taskTitle'] as String,
  changeType: json['changeType'] as String,
  oldTime: json['oldTime'] as String?,
  newTime: json['newTime'] as String?,
);

Map<String, dynamic> _$ScheduleChangeItemDtoToJson(
  _ScheduleChangeItemDto instance,
) => <String, dynamic>{
  'taskId': instance.taskId,
  'taskTitle': instance.taskTitle,
  'changeType': instance.changeType,
  'oldTime': instance.oldTime,
  'newTime': instance.newTime,
};

_ScheduleChangesDto _$ScheduleChangesDtoFromJson(Map<String, dynamic> json) =>
    _ScheduleChangesDto(
      hasMeaningfulChanges: json['hasMeaningfulChanges'] as bool,
      changeCount: (json['changeCount'] as num).toInt(),
      changes: (json['changes'] as List<dynamic>)
          .map((e) => ScheduleChangeItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScheduleChangesDtoToJson(_ScheduleChangesDto instance) =>
    <String, dynamic>{
      'hasMeaningfulChanges': instance.hasMeaningfulChanges,
      'changeCount': instance.changeCount,
      'changes': instance.changes,
    };
