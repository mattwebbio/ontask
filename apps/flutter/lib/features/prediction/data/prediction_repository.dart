import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/completion_prediction.dart';
import 'completion_prediction_dto.dart';

part 'prediction_repository.g.dart';

/// Repository for prediction API calls.
///
/// Fetches predicted completion data for tasks, lists, and sections.
/// Uses [ApiClient] injected via Riverpod — never constructs ApiClient directly.
class PredictionRepository {
  PredictionRepository(this._client);
  final ApiClient _client;

  /// Fetches predicted completion for a task.
  Future<CompletionPrediction> fetchTaskPrediction(String taskId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/$taskId/prediction',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('No prediction data for task $taskId');
    return CompletionPredictionDto.fromJson(data).toDomain();
  }

  /// Fetches predicted completion for a list.
  Future<CompletionPrediction> fetchListPrediction(String listId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/lists/$listId/prediction',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('No prediction data for list $listId');
    return CompletionPredictionDto.fromJson(data).toDomain();
  }

  /// Fetches predicted completion for a section.
  Future<CompletionPrediction> fetchSectionPrediction(String sectionId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/sections/$sectionId/prediction',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('No prediction data for section $sectionId');
    return CompletionPredictionDto.fromJson(data).toDomain();
  }
}

/// Riverpod provider for [PredictionRepository].
@riverpod
PredictionRepository predictionRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return PredictionRepository(client);
}
