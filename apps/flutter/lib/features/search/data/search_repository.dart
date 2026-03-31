import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/search_filter.dart';
import '../domain/search_result.dart';
import 'search_result_dto.dart';

part 'search_repository.g.dart';

/// Repository for task search operations via `GET /v1/tasks/search`.
///
/// All network calls go through [ApiClient] injected via Riverpod.
class SearchRepository {
  SearchRepository(this._client);
  final ApiClient _client;

  /// Searches tasks with optional text query and filter criteria.
  ///
  /// Returns a list of [SearchResult] items enriched with list context.
  Future<List<SearchResult>> search({
    String? query,
    SearchFilter? filter,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (filter?.listId != null) 'listId': filter!.listId,
      if (filter?.status != null) 'status': filter!.status!.toApiValue(),
      if (filter?.dueDateFrom != null)
        'dueDateFrom':
            filter!.dueDateFrom!.toIso8601String().split('T').first,
      if (filter?.dueDateTo != null)
        'dueDateTo': filter!.dueDateTo!.toIso8601String().split('T').first,
      if (filter?.hasStake == true) 'hasStake': 'true',
      if (cursor != null) 'cursor': cursor,
    };

    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/search',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return [];

    final items = (data['data'] as List?)
            ?.map(
                (e) => SearchResultDto.fromJson(e as Map<String, dynamic>).toDomain())
            .toList() ??
        [];
    return items;
  }
}

/// Riverpod provider for [SearchRepository].
@riverpod
SearchRepository searchRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return SearchRepository(client);
}
