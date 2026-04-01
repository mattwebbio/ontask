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
  isShared: json['isShared'] as bool? ?? false,
  memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
  memberAvatarInitials:
      (json['memberAvatarInitials'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  assignmentStrategy: json['assignmentStrategy'] as String?,
  proofRequirement: json['proofRequirement'] as String?,
);

Map<String, dynamic> _$ListDtoToJson(_ListDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'defaultDueDate': instance.defaultDueDate,
  'position': instance.position,
  'archivedAt': instance.archivedAt,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'isShared': instance.isShared,
  'memberCount': instance.memberCount,
  'memberAvatarInitials': instance.memberAvatarInitials,
  'assignmentStrategy': instance.assignmentStrategy,
  'proofRequirement': instance.proofRequirement,
};
