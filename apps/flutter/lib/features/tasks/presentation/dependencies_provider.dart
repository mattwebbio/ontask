import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/tasks_repository.dart';
import '../domain/task_dependency.dart';

part 'dependencies_provider.g.dart';

/// State holding both directions of dependencies for a task.
typedef DependencyState =
    ({List<TaskDependency> dependsOn, List<TaskDependency> blocks});

/// Notifier managing dependency state for a specific task.
///
/// Loads, adds, and removes dependencies via [TasksRepository].
@riverpod
class Dependencies extends _$Dependencies {
  @override
  Future<DependencyState> build({required String taskId}) async {
    final repo = ref.read(tasksRepositoryProvider);
    return repo.getDependencies(taskId);
  }

  /// Adds a dependency: the current task depends on [dependsOnTaskId].
  Future<void> addDependency(String dependsOnTaskId) async {
    final repo = ref.read(tasksRepositoryProvider);
    final dep = await repo.createDependency(
      dependentTaskId: taskId,
      dependsOnTaskId: dependsOnTaskId,
    );
    final current = state.value ??
        (dependsOn: <TaskDependency>[], blocks: <TaskDependency>[]);
    state = AsyncData((
      dependsOn: [...current.dependsOn, dep],
      blocks: current.blocks,
    ));
  }

  /// Removes a dependency by its ID.
  Future<void> removeDependency(String dependencyId) async {
    final repo = ref.read(tasksRepositoryProvider);
    await repo.deleteDependency(dependencyId);
    final current = state.value ??
        (dependsOn: <TaskDependency>[], blocks: <TaskDependency>[]);
    state = AsyncData((
      dependsOn:
          current.dependsOn.where((d) => d.id != dependencyId).toList(),
      blocks: current.blocks.where((d) => d.id != dependencyId).toList(),
    ));
  }
}
