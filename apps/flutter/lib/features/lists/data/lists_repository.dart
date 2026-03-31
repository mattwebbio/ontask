import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/task_list.dart';
import 'list_dto.dart';

part 'lists_repository.g.dart';

/// Repository for list CRUD operations via the `/v1/lists` API.
class ListsRepository {
  ListsRepository(this._client);
  final ApiClient _client;

  /// Creates a new list. Returns the created [TaskList].
  Future<TaskList> createList({
    required String title,
    String? defaultDueDate,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/lists',
      data: {
        'title': title,
        if (defaultDueDate != null) 'defaultDueDate': defaultDueDate,
      },
    );
    return ListDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Fetches all lists for the current user.
  Future<List<TaskList>> getLists() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/v1/lists');
    final items = (response.data!['data'] as List)
        .map((e) => ListDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return items;
  }

  /// Fetches a single list by ID.
  Future<TaskList> getList(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/lists/$id',
    );
    return ListDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Updates list properties (PATCH semantics).
  Future<TaskList> updateList(String id, Map<String, dynamic> fields) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/v1/lists/$id',
      data: fields,
    );
    return ListDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Archives a list (soft delete — sets archivedAt, cascades to tasks).
  Future<void> archiveList(String id) async {
    await _client.dio.delete('/v1/lists/$id/archive');
  }
}

/// Riverpod provider for [ListsRepository].
@riverpod
ListsRepository listsRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return ListsRepository(client);
}
