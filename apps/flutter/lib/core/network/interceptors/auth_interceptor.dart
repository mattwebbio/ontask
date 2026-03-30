import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared-preferences key for the access token.
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
class AuthInterceptor extends Interceptor {
  AuthInterceptor({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

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
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(kAccessToken);
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
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(kRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // TODO(story-1.8): Replace with real refresh endpoint once auth API is
      // wired up. For now returns false (no real endpoint yet) so callers
      // exercise the force-logout path.
      return false;
    } catch (e) {
      debugPrint('[AuthInterceptor] _tryRefreshToken error: $e');
      return false;
    }
  }

  Future<void> _forceSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kAccessToken);
      await prefs.remove(kRefreshToken);
      // TODO(story-1.8): Dispatch a sign-out navigation event via Riverpod
      // once the auth provider exists.
      debugPrint('[AuthInterceptor] Sign-out: tokens cleared');
    } catch (e) {
      debugPrint('[AuthInterceptor] _forceSignOut error: $e');
    }
  }
}
