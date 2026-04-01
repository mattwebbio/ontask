import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/task_parse_result.dart';
import 'task_parse_result_dto.dart';

part 'nlp_task_repository.g.dart';

/// Repository for NLP task capture API calls (FR1b).
///
/// Provides natural language task parsing by calling `POST /v1/tasks/parse`.
/// Uses [ApiClient] injected via Riverpod — never constructs ApiClient directly.
///
/// This repository belongs in `features/shell/data/` because NLP capture is
/// an input surface concern of the Add tab, not a task CRUD concern.
class NlpTaskRepository {
  NlpTaskRepository(this._client);
  final ApiClient _client;

  /// Parses a natural language utterance into structured task properties.
  ///
  /// Calls `POST /v1/tasks/parse` with the utterance and returns a
  /// [TaskParseResult] for user review before task creation.
  ///
  /// Does NOT create a task — call [TasksNotifier.createTask] after
  /// the user confirms the parsed fields.
  ///
  /// Throws [DioException] on network errors or non-2xx responses.
  Future<TaskParseResult> parseUtterance(String utterance) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/parse',
      data: {'utterance': utterance},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No parse data in response');
    }
    return TaskParseResultDto.fromJson(data).toDomain();
  }
}

/// Riverpod provider for [NlpTaskRepository].
@riverpod
NlpTaskRepository nlpTaskRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return NlpTaskRepository(client);
}
