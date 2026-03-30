import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../features/auth/data/token_storage.dart';

/// Documented constants — kept for readability and test reference.
/// Tokens are now stored in [TokenStorage] (Keychain-backed), NOT [SharedPreferences].
const kAccessToken = 'access_token';
const kRefreshToken = 'refresh_token';

/// Header key used to flag that a request has already been retried so we can
/// detect a second consecutive 401 and force sign-out.
const kRetryHeader = 'X-Retry-401';

/// Global 401 interceptor — ARCH-20.
///
/// Flow:
///   1. 401 received → attempt silent token refresh via stored refresh token.
///   2. If refresh succeeds → attach new access token and retry the original
///      request once (flag it with [kRetryHeader]).
///   3. If the retry also returns 401 (second consecutive) → force sign-out.
///   4. If the refresh itself fails → force sign-out immediately.
///
/// The end-user NEVER sees a raw 401 error — all 401s are either silently
/// recovered or converted into a sign-out navigation action.
///
/// [onSignOut] is injected by [ApiClient] and calls
/// [AuthStateNotifier.setUnauthenticated] to trigger router redirect.
/// This callback pattern avoids a circular dependency between
/// [AuthInterceptor] and [AuthStateNotifier].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({Dio? dio, TokenStorage? tokenStorage, this.onSignOut})
      : _dio = dio ?? Dio(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Called after tokens are cleared on sign-out.
  /// Injects the auth state notifier's [setUnauthenticated] so the router
  /// can react without a direct Riverpod dependency in this interceptor.
  final VoidCallback? onSignOut;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Access token attachment is handled by the retry path after refresh.
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Kick off async handling without making the overridden method async
    // (Dio's Interceptor.onError signature is void, not Future<void>).
    _handleError(err, handler);
  }

  /// Async implementation of the 401-handling logic.
  ///
  /// Exposed as a separate method so it can be called directly in unit tests.
  Future<void> handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) =>
      _handleError(err, handler);

  Future<void> _handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // If this request was already retried, this is the second consecutive 401.
    if (err.requestOptions.headers.containsKey(kRetryHeader)) {
      debugPrint('[AuthInterceptor] Second consecutive 401 — forcing sign-out');
      await _forceSignOut();
      handler.reject(err);
      return;
    }

    // First 401 — attempt silent token refresh.
    final refreshed = await _tryRefreshToken();
    if (!refreshed) {
      debugPrint('[AuthInterceptor] Token refresh failed — forcing sign-out');
      await _forceSignOut();
      handler.reject(err);
      return;
    }

    // Refresh succeeded — retry the original request once.
    try {
      final retryOptions = err.requestOptions
        ..headers[kRetryHeader] = '1';
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null) {
        retryOptions.headers['Authorization'] = 'Bearer $accessToken';
      }
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      if (retryErr.response?.statusCode == 401) {
        debugPrint(
          '[AuthInterceptor] Retry returned 401 — forcing sign-out',
        );
        await _forceSignOut();
        handler.reject(retryErr);
      } else {
        handler.next(retryErr);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // POST /v1/auth/refresh with the stored refresh token.
      // On success, persist the new access and refresh tokens.
      // The old refresh token is immediately invalidated by the server (NFR-S5).
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) return false;

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } catch (e) {
      debugPrint('[AuthInterceptor] _tryRefreshToken error: $e');
      return false;
    }
  }

  Future<void> _forceSignOut() async {
    try {
      await _tokenStorage.clearTokens();
      // Notify the auth state notifier to reset to unauthenticated,
      // triggering the GoRouter redirect to /auth/sign-in.
      onSignOut?.call();
      debugPrint('[AuthInterceptor] Sign-out: tokens cleared');
    } catch (e) {
      debugPrint('[AuthInterceptor] _forceSignOut error: $e');
    }
  }
}
