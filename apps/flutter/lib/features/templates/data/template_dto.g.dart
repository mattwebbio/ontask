// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TemplateDto _$TemplateDtoFromJson(Map<String, dynamic> json) => _TemplateDto(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  sourceType: json['sourceType'] as String,
  templateData: json['templateData'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$TemplateDtoToJson(_TemplateDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'sourceType': instance.sourceType,
      'templateData': instance.templateData,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
