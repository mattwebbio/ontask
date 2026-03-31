import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/task.dart';
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
}

/// Riverpod provider for [TasksRepository].
@riverpod
TasksRepository tasksRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return TasksRepository(client);
}
