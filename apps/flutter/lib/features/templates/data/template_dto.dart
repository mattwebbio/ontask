import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/template.dart';

part 'template_dto.freezed.dart';
part 'template_dto.g.dart';

/// Data transfer object for the `/v1/templates` API response.
@freezed
abstract class TemplateDto with _$TemplateDto {
  const TemplateDto._();

  const factory TemplateDto({
    required String id,
    required String userId,
    required String title,
    required String sourceType,
    String? templateData,
    required String createdAt,
    String? updatedAt,
  }) = _TemplateDto;

  factory TemplateDto.fromJson(Map<String, dynamic> json) =>
      _$TemplateDtoFromJson(json);

  /// Converts this DTO to a [Template] domain model.
  Template toDomain() => Template(
        id: id,
        userId: userId,
        title: title,
        sourceType: sourceType,
        templateData: templateData,
        createdAt: DateTime.parse(createdAt),
        updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
      );
}
