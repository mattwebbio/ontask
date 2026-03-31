// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskDto _$TaskDtoFromJson(Map<String, dynamic> json) => _TaskDto(
  id: json['id'] as String,
  title: json['title'] as String,
  notes: json['notes'] as String?,
  dueDate: json['dueDate'] as String?,
  listId: json['listId'] as String?,
  sectionId: json['sectionId'] as String?,
  parentTaskId: json['parentTaskId'] as String?,
  position: (json['position'] as num).toInt(),
  archivedAt: json['archivedAt'] as String?,
  completedAt: json['completedAt'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$TaskDtoToJson(_TaskDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'notes': instance.notes,
  'dueDate': instance.dueDate,
  'listId': instance.listId,
  'sectionId': instance.sectionId,
  'parentTaskId': instance.parentTaskId,
  'position': instance.position,
  'archivedAt': instance.archivedAt,
  'completedAt': instance.completedAt,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
