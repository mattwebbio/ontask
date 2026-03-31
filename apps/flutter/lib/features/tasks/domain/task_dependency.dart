import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_dependency.freezed.dart';

/// Domain model for a task dependency relationship.
///
/// Represents a directional dependency: the task identified by
/// [dependentTaskId] depends on (waits for) the task identified
/// by [dependsOnTaskId].
@freezed
abstract class TaskDependency with _$TaskDependency {
  const factory TaskDependency({
    required String id,
    required String dependentTaskId,
    required String dependsOnTaskId,
    required DateTime createdAt,
  }) = _TaskDependency;
}
