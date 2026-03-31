// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_health_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayHealthDto _$DayHealthDtoFromJson(Map<String, dynamic> json) =>
    _DayHealthDto(
      date: json['date'] as String,
      status: json['status'] as String,
      taskCount: (json['taskCount'] as num).toInt(),
      capacityPercent: (json['capacityPercent'] as num).toDouble(),
      atRiskTaskIds: (json['atRiskTaskIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DayHealthDtoToJson(_DayHealthDto instance) =>
    <String, dynamic>{
      'date': instance.date,
      'status': instance.status,
      'taskCount': instance.taskCount,
      'capacityPercent': instance.capacityPercent,
      'atRiskTaskIds': instance.atRiskTaskIds,
    };
