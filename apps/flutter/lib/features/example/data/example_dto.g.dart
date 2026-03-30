// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExampleDto _$ExampleDtoFromJson(Map<String, dynamic> json) => _ExampleDto(
  id: json['id'] as String,
  title: json['title'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$ExampleDtoToJson(_ExampleDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'isCompleted': instance.isCompleted,
    };
