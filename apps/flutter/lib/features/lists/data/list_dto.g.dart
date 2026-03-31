// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListDto _$ListDtoFromJson(Map<String, dynamic> json) => _ListDto(
  id: json['id'] as String,
  title: json['title'] as String,
  defaultDueDate: json['defaultDueDate'] as String?,
  position: (json['position'] as num).toInt(),
  archivedAt: json['archivedAt'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$ListDtoToJson(_ListDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'defaultDueDate': instance.defaultDueDate,
  'position': instance.position,
  'archivedAt': instance.archivedAt,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
