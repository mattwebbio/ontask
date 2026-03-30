import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/example.dart';
import '../domain/i_example_repository.dart';
import 'example_dto.dart';

part 'example_repository.g.dart';

/// Concrete implementation of [IExampleRepository].
///
/// Fetches examples from the API via [ApiClient] (Riverpod-injected — never
/// instantiated directly).
class ExampleRepository implements IExampleRepository {
  const ExampleRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<Example>> fetchAll() async {
    final response = await apiClient.dio.get<List<dynamic>>('/examples');
    final data = response.data ?? [];
    return data
        .map((e) => ExampleDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
  }
}

/// Riverpod provider for [IExampleRepository].
///
/// Returns the concrete [ExampleRepository]; tests override with a mock.
@riverpod
IExampleRepository exampleRepository(Ref ref) {
  return ExampleRepository(apiClient: ref.watch(apiClientProvider));
}
