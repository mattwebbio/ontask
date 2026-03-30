import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/interceptors/auth_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthInterceptor — 401 handling (ARCH-20)', () {
    test(
        'first 401 with no refresh token forces sign-out and rejects the error',
        () async {
      // Arrange: no refresh token → refresh fails → force sign-out + reject.
      SharedPreferences.setMockInitialValues({});

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
        SharedPreferences.setMockInitialValues({});

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

    test('tokens are cleared from SharedPreferences on force sign-out',
        () async {
      SharedPreferences.setMockInitialValues({
        kAccessToken: 'old-access-token',
        kRefreshToken: '', // empty → refresh fails → sign-out
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

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(kAccessToken),
        isNull,
        reason: 'Access token should be cleared after sign-out',
      );
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
