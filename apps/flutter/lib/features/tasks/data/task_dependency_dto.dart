import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/task_dependency.dart';

part 'task_dependency_dto.freezed.dart';
part 'task_dependency_dto.g.dart';

/// Data transfer object for the `/v1/task-dependencies` API response.
///
/// Handles JSON serialisation and maps to the [TaskDependency] domain model
/// via [toDomain].
@freezed
abstract class TaskDependencyDto with _$TaskDependencyDto {
  const TaskDependencyDto._();

  const factory TaskDependencyDto({
    required String id,
    required String dependentTaskId,
    required String dependsOnTaskId,
    required String createdAt,
  }) = _TaskDependencyDto;

  factory TaskDependencyDto.fromJson(Map<String, dynamic> json) =>
      _$TaskDependencyDtoFromJson(json);

  /// Converts this DTO to a [TaskDependency] domain model.
  TaskDependency toDomain() => TaskDependency(
        id: id,
        dependentTaskId: dependentTaskId,
        dependsOnTaskId: dependsOnTaskId,
        createdAt: DateTime.parse(createdAt),
      );
}
