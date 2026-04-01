import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/section.dart';

part 'section_dto.freezed.dart';
part 'section_dto.g.dart';

/// Data transfer object for the `/v1/sections` API response.
@freezed
abstract class SectionDto with _$SectionDto {
  const SectionDto._();

  const factory SectionDto({
    required String id,
    required String listId,
    String? parentSectionId,
    required String title,
    String? defaultDueDate,
    required int position,
    required String createdAt,
    required String updatedAt,
    @JsonKey(defaultValue: null) String? proofRequirement,
  }) = _SectionDto;

  factory SectionDto.fromJson(Map<String, dynamic> json) =>
      _$SectionDtoFromJson(json);

  /// Converts this DTO to a [Section] domain model.
  Section toDomain() => Section(
        id: id,
        listId: listId,
        parentSectionId: parentSectionId,
        title: title,
        defaultDueDate:
            defaultDueDate != null ? DateTime.parse(defaultDueDate!) : null,
        position: position,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        proofRequirement: proofRequirement,
      );
}
