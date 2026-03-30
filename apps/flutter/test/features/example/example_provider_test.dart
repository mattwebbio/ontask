import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/example/data/example_repository.dart';
import 'package:ontask/features/example/domain/example.dart';
import 'package:ontask/features/example/domain/i_example_repository.dart';
import 'package:ontask/features/example/presentation/example_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockExampleRepository extends Mock implements IExampleRepository {}

void main() {
  group('examplesProvider', () {
    test('returns list of examples from repository', () async {
      // Arrange
      final mockRepo = MockExampleRepository();
      final examples = [
        const Example(id: '1', title: 'Task A'),
        const Example(id: '2', title: 'Task B', isCompleted: true),
      ];
      when(() => mockRepo.fetchAll()).thenAnswer((_) async => examples);

      final container = ProviderContainer(
        overrides: [
          exampleRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Act — provider returns AsyncValue<List<Example>>
      final result = await container.read(examplesProvider.future);

      // Assert
      expect(result, equals(examples));
      expect(result, isA<List<Example>>());
      verify(() => mockRepo.fetchAll()).called(1);
    });

    test('provider wraps future in AsyncValue (not raw Future)', () async {
      final mockRepo = MockExampleRepository();
      when(() => mockRepo.fetchAll()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          exampleRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // The provider state is AsyncValue — not a raw Future.
      final asyncValue = container.read(examplesProvider);
      expect(asyncValue, isA<AsyncValue<List<Example>>>());
    });

    test('provider reflects loading state before future completes', () {
      final mockRepo = MockExampleRepository();
      // Never resolves → stays in loading.
      when(() => mockRepo.fetchAll()).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 60), () => []),
      );

      final container = ProviderContainer(
        overrides: [
          exampleRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = container.read(examplesProvider);
      expect(asyncValue, isA<AsyncLoading<List<Example>>>());
    });

    test('provider reflects error state when repository throws', () async {
      final mockRepo = MockExampleRepository();
      when(() => mockRepo.fetchAll()).thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          exampleRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future to settle into an error state.
      // Riverpod auto-dispose providers may retry; ignore the exception and
      // read the provider state directly.
      try {
        await container.read(examplesProvider.future);
      } catch (_) {
        // Expected — the repository throws.
      }

      final asyncValue = container.read(examplesProvider);
      // The value must be either AsyncError or AsyncLoading with a previous error.
      // In Riverpod 3.x, a thrown exception lands in AsyncError.
      expect(asyncValue.hasError, isTrue,
          reason: 'Provider should reflect the repository error');
    });

    test('apiClientProvider can be overridden (injection pattern validation)', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);

      // Verify the mock is returned via the provider — not a real ApiClient.
      final client = container.read(apiClientProvider);
      expect(client, same(mockClient));
    });
  });
}
