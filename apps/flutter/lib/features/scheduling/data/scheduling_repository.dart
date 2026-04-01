import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/schedule_explanation.dart';
import 'schedule_explanation_dto.dart';

part 'scheduling_repository.g.dart';

/// Repository for scheduling-related API calls.
///
/// Fetches scheduling explanations for tasks via
/// `GET /v1/tasks/:id/schedule` (FR13).
/// Uses [ApiClient] injected via Riverpod — never constructs ApiClient directly.
class SchedulingRepository {
  SchedulingRepository(this._client);
  final ApiClient _client;

  /// Fetches the scheduling explanation for a task.
  ///
  /// Calls `GET /v1/tasks/:taskId/schedule` and extracts the
  /// `explanation` sub-object, mapping it to a [ScheduleExplanation].
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/$taskId/schedule',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No schedule data for task $taskId');
    }
    final explanationJson = data['explanation'] as Map<String, dynamic>?;
    if (explanationJson == null) {
      throw Exception('No explanation in schedule response for task $taskId');
    }
    return ScheduleExplanationDto.fromJson(explanationJson).toDomain();
  }
}

/// Riverpod provider for [SchedulingRepository].
@riverpod
SchedulingRepository schedulingRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return SchedulingRepository(client);
}
