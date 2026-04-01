// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarEventDto _$CalendarEventDtoFromJson(Map<String, dynamic> json) =>
    _CalendarEventDto(
      id: json['id'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isAllDay: json['isAllDay'] as bool,
      summary: json['summary'] as String?,
    );

Map<String, dynamic> _$CalendarEventDtoToJson(_CalendarEventDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'isAllDay': instance.isAllDay,
      'summary': instance.summary,
    };
