import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  // Required because reading apiClientProvider initialises AuthStateNotifier,
  // which calls TokenStorage (flutter_secure_storage) — a platform channel.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ApiClient — Riverpod injection', () {
    test('apiClientProvider creates an ApiClient instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(apiClientProvider);
      expect(client, isA<ApiClient>());
    });

    test('two reads of apiClientProvider return the same instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(apiClientProvider);
      final second = container.read(apiClientProvider);
      // Auto-dispose providers re-create on each read from a fresh container,
      // but within the same read cycle they are identical.
      expect(first, same(second));
    });

    test('apiClientProvider can be overridden in tests (Riverpod injection pattern)', () {
      final mock = MockApiClient();
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(apiClientProvider);
      expect(client, same(mock));
      expect(client, isA<MockApiClient>());
    });

    test('ApiClient exposes a non-null Dio instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(apiClientProvider);
      // ignore: invalid_use_of_protected_member
      expect(client.dio, isNotNull);
    });
  });
}
