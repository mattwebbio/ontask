import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/task_list.dart';

part 'list_dto.freezed.dart';
part 'list_dto.g.dart';

/// Data transfer object for the `/v1/lists` API response.
@freezed
abstract class ListDto with _$ListDto {
  const ListDto._();

  const factory ListDto({
    required String id,
    required String title,
    String? defaultDueDate,
    required int position,
    String? archivedAt,
    required String createdAt,
    required String updatedAt,
  }) = _ListDto;

  factory ListDto.fromJson(Map<String, dynamic> json) => _$ListDtoFromJson(json);

  /// Converts this DTO to a [TaskList] domain model.
  TaskList toDomain() => TaskList(
        id: id,
        title: title,
        defaultDueDate:
            defaultDueDate != null ? DateTime.parse(defaultDueDate!) : null,
        position: position,
        archivedAt: archivedAt != null ? DateTime.parse(archivedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
