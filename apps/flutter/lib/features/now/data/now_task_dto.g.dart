// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_task_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NowTaskDto _$NowTaskDtoFromJson(Map<String, dynamic> json) => _NowTaskDto(
  id: json['id'] as String,
  title: json['title'] as String,
  notes: json['notes'] as String?,
  dueDate: json['dueDate'] as String?,
  listId: json['listId'] as String?,
  listName: json['listName'] as String?,
  assignorName: json['assignorName'] as String?,
  stakeAmountCents: (json['stakeAmountCents'] as num?)?.toInt(),
  proofMode: json['proofMode'] as String?,
  completedAt: json['completedAt'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$NowTaskDtoToJson(_NowTaskDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'notes': instance.notes,
      'dueDate': instance.dueDate,
      'listId': instance.listId,
      'listName': instance.listName,
      'assignorName': instance.assignorName,
      'stakeAmountCents': instance.stakeAmountCents,
      'proofMode': instance.proofMode,
      'completedAt': instance.completedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
