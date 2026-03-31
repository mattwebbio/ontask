import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_dependency.dart';
import 'task_dependency_dto.dart';
import 'task_dto.dart';

part 'tasks_repository.g.dart';

/// Repository for task CRUD operations via the `/v1/tasks` API.
///
/// All network calls go through [ApiClient] injected via Riverpod.
class TasksRepository {
  TasksRepository(this._client);
  final ApiClient _client;

  /// Creates a new task. Returns the created [Task].
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
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks',
      data: {
        'title': title,
        if (notes != null) 'notes': notes,
        if (dueDate != null) 'dueDate': dueDate,
        if (listId != null) 'listId': listId,
        if (sectionId != null) 'sectionId': sectionId,
        if (parentTaskId != null) 'parentTaskId': parentTaskId,
        if (timeWindow != null) 'timeWindow': timeWindow,
        if (timeWindowStart != null) 'timeWindowStart': timeWindowStart,
        if (timeWindowEnd != null) 'timeWindowEnd': timeWindowEnd,
        if (energyRequirement != null) 'energyRequirement': energyRequirement,
        if (priority != null) 'priority': priority,
        if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
        if (recurrenceInterval != null) 'recurrenceInterval': recurrenceInterval,
        if (recurrenceDaysOfWeek != null) 'recurrenceDaysOfWeek': recurrenceDaysOfWeek,
        if (recurrenceParentId != null) 'recurrenceParentId': recurrenceParentId,
      },
    );
    return TaskDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Fetches tasks with optional filters and cursor-based pagination.
  Future<List<Task>> getTasks({
    String? listId,
    String? sectionId,
    bool? archived,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{
      if (listId != null) 'listId': listId,
      if (sectionId != null) 'sectionId': sectionId,
      if (archived != null) 'archived': archived.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks',
      queryParameters: queryParams,
    );
    final items = (response.data!['data'] as List)
        .map((e) => TaskDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return items;
  }

  /// Fetches a single task by ID.
  Future<Task> getTask(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/$id',
    );
    return TaskDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Updates task properties (PATCH semantics — only changed fields).
  Future<Task> updateTask(String id, Map<String, dynamic> fields) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/v1/tasks/$id',
      data: fields,
    );
    return TaskDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Completes a task. For recurring tasks, returns both the completed task
  /// and the auto-generated next instance.
  Future<({Task completed, Task? nextInstance})> completeTask(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$id/complete',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final completed = TaskDto.fromJson(
      data['completedTask'] as Map<String, dynamic>,
    ).toDomain();
    final nextInstanceData = data['nextInstance'];
    final nextInstance = nextInstanceData != null
        ? TaskDto.fromJson(nextInstanceData as Map<String, dynamic>).toDomain()
        : null;
    return (completed: completed, nextInstance: nextInstance);
  }

  /// Archives a task (soft delete — sets archivedAt).
  Future<void> archiveTask(String id) async {
    await _client.dio.delete('/v1/tasks/$id/archive');
  }

  /// Updates task position (reorder).
  Future<Task> reorderTask(String id, int position) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/v1/tasks/$id/reorder',
      data: {'position': position},
    );
    return TaskDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  // ── Task Dependencies ───────────────────────────────────────────────────

  /// Fetches all dependencies for a task (both directions).
  /// Returns a record with `dependsOn` and `blocks` lists.
  Future<({List<TaskDependency> dependsOn, List<TaskDependency> blocks})>
      getDependencies(String taskId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/task-dependencies',
      queryParameters: {'taskId': taskId},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final dependsOn = (data['dependsOn'] as List)
        .map((e) =>
            TaskDependencyDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    final blocks = (data['blocks'] as List)
        .map((e) =>
            TaskDependencyDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return (dependsOn: dependsOn, blocks: blocks);
  }

  /// Creates a dependency: [dependentTaskId] depends on [dependsOnTaskId].
  Future<TaskDependency> createDependency({
    required String dependentTaskId,
    required String dependsOnTaskId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/task-dependencies',
      data: {
        'dependentTaskId': dependentTaskId,
        'dependsOnTaskId': dependsOnTaskId,
      },
    );
    return TaskDependencyDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Deletes a dependency by ID.
  Future<void> deleteDependency(String id) async {
    await _client.dio.delete('/v1/task-dependencies/$id');
  }

  // ── Bulk Operations ─────────────────────────────────────────────────────

  /// Reschedules multiple tasks to a new due date.
  Future<({List<String> succeeded, List<({String id, String error})> failed})>
      bulkReschedule(List<String> taskIds, String dueDate) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/bulk/reschedule',
      data: {'taskIds': taskIds, 'dueDate': dueDate},
    );
    return _parseBulkResult(response.data!);
  }

  /// Marks multiple tasks as completed.
  Future<({List<String> succeeded, List<({String id, String error})> failed})>
      bulkComplete(List<String> taskIds) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/bulk/complete',
      data: {'taskIds': taskIds},
    );
    return _parseBulkResult(response.data!);
  }

  /// Archives multiple tasks (soft delete).
  Future<({List<String> succeeded, List<({String id, String error})> failed})>
      bulkDelete(List<String> taskIds) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/bulk/delete',
      data: {'taskIds': taskIds},
    );
    return _parseBulkResult(response.data!);
  }

  /// Parses the partial-success bulk result envelope.
  ({List<String> succeeded, List<({String id, String error})> failed})
      _parseBulkResult(Map<String, dynamic> responseData) {
    final data = responseData['data'] as Map<String, dynamic>;
    final succeeded =
        (data['succeeded'] as List).cast<String>();
    final failed = (data['failed'] as List)
        .map((e) {
          final map = e as Map<String, dynamic>;
          return (id: map['id'] as String, error: map['error'] as String);
        })
        .toList();
    return (succeeded: succeeded, failed: failed);
  }
}

/// Riverpod provider for [TasksRepository].
@riverpod
TasksRepository tasksRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return TasksRepository(client);
}
