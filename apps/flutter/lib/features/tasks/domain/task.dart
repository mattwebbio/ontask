import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';

/// Core task domain model.
///
/// Maps to the `tasks` table and the `/v1/tasks` API response.
/// Timestamps use nullable [DateTime] — null means "not set / not applicable".
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? notes,
    DateTime? dueDate,
    String? listId,
    String? sectionId,
    String? parentTaskId,
    required int position,
    DateTime? archivedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}
