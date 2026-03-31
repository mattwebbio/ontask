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
    final data = response.data!['data'];
    if (data == null) return null;
    return NowTaskDto.fromJson(data as Map<String, dynamic>).toDomain();
  }
}

/// Riverpod provider for [NowRepository].
@riverpod
NowRepository nowRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return NowRepository(client);
}
