// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SectionDto _$SectionDtoFromJson(Map<String, dynamic> json) => _SectionDto(
  id: json['id'] as String,
  listId: json['listId'] as String,
  parentSectionId: json['parentSectionId'] as String?,
  title: json['title'] as String,
  defaultDueDate: json['defaultDueDate'] as String?,
  position: (json['position'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  proofRequirement: json['proofRequirement'] as String?,
);

Map<String, dynamic> _$SectionDtoToJson(_SectionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listId': instance.listId,
      'parentSectionId': instance.parentSectionId,
      'title': instance.title,
      'defaultDueDate': instance.defaultDueDate,
      'position': instance.position,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'proofRequirement': instance.proofRequirement,
    };
