import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/interceptors/auth_interceptor.dart';
import 'package:ontask/features/auth/data/token_storage.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthInterceptor — 401 handling (ARCH-20)', () {
    test(
        'first 401 with no refresh token forces sign-out and rejects the error',
        () async {
      // Arrange: no refresh token → refresh fails → force sign-out + reject.
      FlutterSecureStorage.setMockInitialValues({});

      final interceptor = AuthInterceptor(dio: Dio());
      bool rejected = false;

      final requestOptions = RequestOptions(path: '/test');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      final handler = _CapturingErrorHandler(
        onReject: (_) => rejected = true,
      );

      // Use the public async helper so the test can await completion.
      await interceptor.handleError(dioError, handler);

      expect(
        rejected,
        isTrue,
        reason:
            'First 401 with no refresh token should force sign-out and reject',
      );
    });

    test(
      'second consecutive 401 (retry header present) immediately rejects',
      () async {
        FlutterSecureStorage.setMockInitialValues({});

        final interceptor = AuthInterceptor(dio: Dio());
        bool rejected = false;

        // Request already has the retry header → second 401 → force sign-out.
        final requestOptions = RequestOptions(
          path: '/test',
          headers: {kRetryHeader: '1'},
        );
        final dioError = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
        );

        final handler = _CapturingErrorHandler(
          onReject: (_) => rejected = true,
        );

        await interceptor.handleError(dioError, handler);

        expect(
          rejected,
          isTrue,
          reason: 'Second consecutive 401 should be immediately rejected',
        );
      },
    );

    test('non-401 errors pass through via handler.next', () async {
      FlutterSecureStorage.setMockInitialValues({});

      final interceptor = AuthInterceptor(dio: Dio());
      bool passed = false;

      final requestOptions = RequestOptions(path: '/test');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 500,
        ),
      );

      final handler = _CapturingErrorHandler(
        onNext: (_) => passed = true,
      );

      await interceptor.handleError(dioError, handler);

      expect(passed, isTrue, reason: 'Non-401 errors should pass through');
    });

    test('tokens are cleared from TokenStorage (Keychain) on force sign-out',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'old-access-token',
        'refresh_token': '', // empty → refresh fails → sign-out
      });

      final interceptor = AuthInterceptor(dio: Dio());

      final requestOptions = RequestOptions(path: '/test');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      final handler = _CapturingErrorHandler(onReject: (_) {});
      await interceptor.handleError(dioError, handler);

      final accessToken = await const TokenStorage().getAccessToken();
      expect(
        accessToken,
        isNull,
        reason: 'Access token should be cleared from Keychain after sign-out',
      );
    });

    test('onSignOut callback is invoked when force sign-out occurs', () async {
      FlutterSecureStorage.setMockInitialValues({});

      bool signedOut = false;
      final interceptor = AuthInterceptor(
        dio: Dio(),
        onSignOut: () => signedOut = true,
      );

      final requestOptions = RequestOptions(path: '/test');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      final handler = _CapturingErrorHandler(onReject: (_) {});
      await interceptor.handleError(dioError, handler);

      expect(
        signedOut,
        isTrue,
        reason:
            'onSignOut callback should be called when force sign-out occurs',
      );
    });

    test(
        '_tryRefreshToken returns false when no refresh token is stored '
        '(verifies AC #3 fallback)', () async {
      FlutterSecureStorage.setMockInitialValues({});

      final interceptor = AuthInterceptor(dio: Dio());
      bool rejected = false;

      final requestOptions = RequestOptions(path: '/test');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      final handler = _CapturingErrorHandler(onReject: (_) => rejected = true);
      await interceptor.handleError(dioError, handler);

      // No refresh token → _tryRefreshToken returns false → force sign-out + reject.
      expect(rejected, isTrue);
    });

    test(
        '_tryRefreshToken calls POST /v1/auth/refresh and stores new tokens '
        'on success (AC #3 positive path)', () async {
      // Arrange: seed a valid refresh token so _tryRefreshToken proceeds.
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'old-access',
        'refresh_token': 'valid-refresh-token',
      });

      final mockDio = MockDio();

      // The interceptor uses _dio for the refresh call AND for retrying the
      // original request.  Stub the refresh endpoint to return new tokens.
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          statusCode: 200,
          data: {
            'data': {
              'accessToken': 'new-access-token',
              'refreshToken': 'new-refresh-token',
            },
          },
        ),
      );

      // Stub fetch() for the retry of the original request — returns 200.
      when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
        ),
      );

      bool resolved = false;
      final interceptor = AuthInterceptor(dio: mockDio);

      final requestOptions = RequestOptions(path: '/test');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      final handler = _CapturingErrorHandler(onResolve: (_) => resolved = true);
      await interceptor.handleError(dioError, handler);

      // Refresh succeeded → original request was retried → resolved.
      expect(resolved, isTrue, reason: 'Request should be resolved after successful token refresh');

      // New tokens must be persisted in TokenStorage (Keychain mock).
      final storage = const TokenStorage();
      expect(await storage.getAccessToken(), 'new-access-token',
          reason: 'New access token must be stored in Keychain after refresh');
      expect(await storage.getRefreshToken(), 'new-refresh-token',
          reason: 'New refresh token must be stored in Keychain after refresh');
    });
  });
}

/// Minimal [ErrorInterceptorHandler] that captures calls for assertions.
class _CapturingErrorHandler extends ErrorInterceptorHandler {
  _CapturingErrorHandler({
    void Function(DioException)? onNext,
    void Function(DioException)? onReject,
    void Function(Response)? onResolve,
  })  : _onNext = onNext,
        _onReject = onReject,
        _onResolve = onResolve;

  final void Function(DioException)? _onNext;
  final void Function(DioException)? _onReject;
  final void Function(Response)? _onResolve;

  @override
  void next(DioException err) => _onNext?.call(err);

  @override
  void reject(DioException err, {bool callFollowingErrorInterceptor = false}) =>
      _onReject?.call(err);

  @override
  void resolve(Response response,
          {bool callFollowingResponseInterceptor = false}) =>
      _onResolve?.call(response);
}
