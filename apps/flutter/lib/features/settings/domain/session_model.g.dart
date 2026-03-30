// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionModel _$SessionModelFromJson(Map<String, dynamic> json) =>
    _SessionModel(
      sessionId: json['sessionId'] as String,
      deviceName: json['deviceName'] as String,
      location: json['location'] as String,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      isCurrentDevice: json['isCurrentDevice'] as bool,
    );

Map<String, dynamic> _$SessionModelToJson(_SessionModel instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'deviceName': instance.deviceName,
      'location': instance.location,
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'isCurrentDevice': instance.isCurrentDevice,
    };
