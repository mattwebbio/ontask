import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/now_task.dart';
import 'now_task_dto.dart';

part 'now_repository.g.dart';

/// Repository for the Now tab's current task endpoint.
///
/// Fetches the single current task from `GET /v1/tasks/current`.
/// Returns `null` when no current task is active (rest state).
class NowRepository {
  NowRepository(this._client);
  final ApiClient _client;

  /// Fetches the current task with enriched Now-specific fields.
  ///
  /// Returns `null` when the API returns `{ data: null }` (rest state).
  Future<NowTask?> getCurrentTask() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/current',
    );
    final responseData = response.data;
    if (responseData == null) return null;
    final data = responseData['data'];
    if (data == null) return null;
    return NowTaskDto.fromJson(data as Map<String, dynamic>).toDomain();
  }

  /// Starts the task timer via `POST /v1/tasks/{id}/start`.
  Future<NowTask> startTask(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$id/start',
    );
    final data = response.data?['data'];
    if (data == null) throw Exception('Invalid start task response');
    return NowTaskDto.fromJson(data as Map<String, dynamic>).toDomain();
  }

  /// Pauses the task timer via `POST /v1/tasks/{id}/pause`.
  Future<NowTask> pauseTask(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$id/pause',
    );
    final data = response.data?['data'];
    if (data == null) throw Exception('Invalid pause task response');
    return NowTaskDto.fromJson(data as Map<String, dynamic>).toDomain();
  }

  /// Stops the task timer via `POST /v1/tasks/{id}/stop`.
  ///
  /// Stopping the timer does NOT mark the task as complete.
  Future<NowTask> stopTask(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$id/stop',
    );
    final data = response.data?['data'];
    if (data == null) throw Exception('Invalid stop task response');
    return NowTaskDto.fromJson(data as Map<String, dynamic>).toDomain();
  }
}

/// Riverpod provider for [NowRepository].
@riverpod
NowRepository nowRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return NowRepository(client);
}
