import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/task.dart';

part 'task_dto.freezed.dart';
part 'task_dto.g.dart';

/// Data transfer object for the `/v1/tasks` API response.
///
/// Handles JSON serialisation and maps to the [Task] domain model via [toDomain].
@freezed
abstract class TaskDto with _$TaskDto {
  const TaskDto._();

  const factory TaskDto({
    required String id,
    required String title,
    String? notes,
    String? dueDate,
    String? listId,
    String? sectionId,
    String? parentTaskId,
    required int position,
    String? archivedAt,
    String? completedAt,
    required String createdAt,
    required String updatedAt,
  }) = _TaskDto;

  factory TaskDto.fromJson(Map<String, dynamic> json) => _$TaskDtoFromJson(json);

  /// Converts this DTO to a [Task] domain model.
  Task toDomain() => Task(
        id: id,
        title: title,
        notes: notes,
        dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
        listId: listId,
        sectionId: sectionId,
        parentTaskId: parentTaskId,
        position: position,
        archivedAt: archivedAt != null ? DateTime.parse(archivedAt!) : null,
        completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
