import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/tasks_repository.dart';
import '../domain/task.dart';

part 'tasks_provider.g.dart';

/// Notifier managing task list state per list/section.
///
/// Exposes create, update, archive, reorder methods.
/// Returns `AsyncValue<List<Task>>`.
@riverpod
class TasksNotifier extends _$TasksNotifier {
  @override
  Future<List<Task>> build({String? listId, String? sectionId}) async {
    final repo = ref.read(tasksRepositoryProvider);
    return repo.getTasks(listId: listId, sectionId: sectionId);
  }

  /// Creates a new task and adds it to the current list.
  Future<Task> createTask({
    required String title,
    String? notes,
    String? dueDate,
    String? listId,
    String? sectionId,
    String? parentTaskId,
    String? timeWindow,
    String? timeWindowStart,
    String? timeWindowEnd,
    String? energyRequirement,
    String? priority,
    String? recurrenceRule,
    int? recurrenceInterval,
    String? recurrenceDaysOfWeek,
    String? recurrenceParentId,
  }) async {
    final repo = ref.read(tasksRepositoryProvider);
    final task = await repo.createTask(
      title: title,
      notes: notes,
      dueDate: dueDate,
      listId: listId,
      sectionId: sectionId,
      parentTaskId: parentTaskId,
      timeWindow: timeWindow,
      timeWindowStart: timeWindowStart,
      timeWindowEnd: timeWindowEnd,
      energyRequirement: energyRequirement,
      priority: priority,
      recurrenceRule: recurrenceRule,
      recurrenceInterval: recurrenceInterval,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek,
      recurrenceParentId: recurrenceParentId,
    );

    // Optimistically add to state
    final current = state.value ?? [];
    state = AsyncData([...current, task]);
    return task;
  }

  /// Completes a task. For recurring tasks, replaces the completed task
  /// and inserts the auto-generated next instance.
  Future<void> completeTask(String id) async {
    final repo = ref.read(tasksRepositoryProvider);
    final result = await repo.completeTask(id);

    final current = state.value ?? [];
    var updated = current.map((t) => t.id == id ? result.completed : t).toList();
    if (result.nextInstance != null) {
      updated = [...updated, result.nextInstance!];
    }
    state = AsyncData(updated);
  }

  /// Updates task properties.
  Future<void> updateTask(String id, Map<String, dynamic> fields) async {
    final repo = ref.read(tasksRepositoryProvider);
    final updated = await repo.updateTask(id, fields);

    final current = state.value ?? [];
    state = AsyncData(
      current.map((t) => t.id == id ? updated : t).toList(),
    );
  }

  /// Archives a task (soft delete).
  Future<void> archiveTask(String id) async {
    final repo = ref.read(tasksRepositoryProvider);
    await repo.archiveTask(id);

    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != id).toList());
  }

  /// Reorders a task to a new position.
  Future<void> reorderTask(String id, int position) async {
    final repo = ref.read(tasksRepositoryProvider);
    final updated = await repo.reorderTask(id, position);

    final current = state.value ?? [];
    state = AsyncData(
      current.map((t) => t.id == id ? updated : t).toList(),
    );
  }
}
