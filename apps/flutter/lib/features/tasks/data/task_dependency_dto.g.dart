// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dependency_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskDependencyDto _$TaskDependencyDtoFromJson(Map<String, dynamic> json) =>
    _TaskDependencyDto(
      id: json['id'] as String,
      dependentTaskId: json['dependentTaskId'] as String,
      dependsOnTaskId: json['dependsOnTaskId'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$TaskDependencyDtoToJson(_TaskDependencyDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dependentTaskId': instance.dependentTaskId,
      'dependsOnTaskId': instance.dependsOnTaskId,
      'createdAt': instance.createdAt,
    };
