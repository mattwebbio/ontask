import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tasks/data/tasks_repository.dart';
import '../data/now_repository.dart';
import '../domain/now_task.dart';

part 'now_provider.g.dart';

/// AsyncNotifier that manages the current task for the Now tab.
///
/// Loads the current task via [NowRepository.getCurrentTask] and supports
/// completing the task and refreshing.
///
/// Returns `AsyncValue<NowTask?>` — null means rest state (no current task).
@riverpod
class Now extends _$Now {
  @override
  Future<NowTask?> build() async {
    final repo = ref.read(nowRepositoryProvider);
    return repo.getCurrentTask();
  }

  /// Completes the current task and refreshes to show the next task.
  Future<void> completeTask(String taskId) async {
    final tasksRepo = ref.read(tasksRepositoryProvider);
    await tasksRepo.completeTask(taskId);
    await refresh();
  }

  /// Re-fetches the current task from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(nowRepositoryProvider);
      return repo.getCurrentTask();
    });
  }
}
