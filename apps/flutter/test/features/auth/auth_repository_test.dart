import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/auth/data/auth_repository.dart';
import 'package:ontask/features/auth/data/token_storage.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns a [ProviderContainer] that overrides [apiClientProvider] with a
/// mock [ApiClient] backed by a mock [Dio].
ProviderContainer _makeContainer(MockApiClient mockClient) {
  return ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(mockClient)],
  );
}

/// Builds a fake successful auth response envelope.
Map<String, dynamic> _successResponse({
  String accessToken = 'access123',
  String refreshToken = 'refresh456',
  String userId = 'user789',
}) =>
    {
      'data': {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
      },
    };

/// Builds a fake error response envelope.
Map<String, dynamic> _errorResponse(String code, String message) => {
      'error': {'code': code, 'message': message},
    };

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthRepository — signInWithEmail', () {
    test('posts to /v1/auth/email and stores tokens in TokenStorage on success',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/v1/auth/email',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/auth/email'),
          statusCode: 200,
          data: _successResponse(
            accessToken: 'at_abc',
            refreshToken: 'rt_def',
            userId: 'u_123',
          ),
        ),
      );

      final container = _makeContainer(mockClient);
      addTearDown(container.dispose);

      final result = await container
          .read(authRepositoryProvider.notifier)
          .signInWithEmail('user@example.com', 'password123');

      // Verify result
      expect(result, isA<Authenticated>());
      expect((result as Authenticated).userId, 'u_123');

      // Verify tokens stored in Keychain (via TokenStorage mock)
      final storage = const TokenStorage();
      expect(await storage.getAccessToken(), 'at_abc');
      expect(await storage.getRefreshToken(), 'rt_def');
    });

    test('returns AuthResult.error when server returns INVALID_CREDENTIALS',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/v1/auth/email',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/auth/email'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/auth/email'),
            statusCode: 401,
            data: _errorResponse(
              'INVALID_CREDENTIALS',
              "That email or password isn't quite right.",
            ),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final container = _makeContainer(mockClient);
      addTearDown(container.dispose);

      final result = await container
          .read(authRepositoryProvider.notifier)
          .signInWithEmail('user@example.com', 'wrong');

      expect(result, isA<AuthError>());
      // Must show plain-language message with no code reference (NFR-UX2)
      final message = (result as AuthError).message;
      expect(message, isNot(contains('INVALID_CREDENTIALS')));
      expect(message, contains("isn't quite right"));
    });
  });

  group('AuthRepository — signOut', () {
    test('clears tokens from TokenStorage on sign-out', () async {
      // Pre-populate storage
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'stored-at',
        'refresh_token': 'stored-rt',
      });

      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      final container = _makeContainer(mockClient);
      addTearDown(container.dispose);

      await container.read(authRepositoryProvider.notifier).signOut();

      final storage = const TokenStorage();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });

  group('TokenStorage — unit tests', () {
    test('saveTokens persists both tokens', () async {
      const storage = TokenStorage();

      await storage.saveTokens(
        accessToken: 'at_hello',
        refreshToken: 'rt_world',
      );

      expect(await storage.getAccessToken(), 'at_hello');
      expect(await storage.getRefreshToken(), 'rt_world');
    });

    test('getAccessToken returns null when no token stored', () async {
      const storage = TokenStorage();
      expect(await storage.getAccessToken(), isNull);
    });

    test('getRefreshToken returns null when no token stored', () async {
      const storage = TokenStorage();
      expect(await storage.getRefreshToken(), isNull);
    });

    test('clearTokens removes both tokens', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'existing-at',
        'refresh_token': 'existing-rt',
      });

      const storage = TokenStorage();
      await storage.clearTokens();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('saveTokens overwrites previously stored tokens', () async {
      const storage = TokenStorage();

      await storage.saveTokens(
        accessToken: 'first-at',
        refreshToken: 'first-rt',
      );
      await storage.saveTokens(
        accessToken: 'second-at',
        refreshToken: 'second-rt',
      );

      expect(await storage.getAccessToken(), 'second-at');
      expect(await storage.getRefreshToken(), 'second-rt');
    });
  });
}
