import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_result.dart';
import 'token_storage.dart';

part 'auth_repository.g.dart';

/// Repository responsible for all authentication flows.
///
/// Injected via Riverpod — never instantiate directly (breaks test overrides).
/// Depends on [ApiClient] via [ref.watch(apiClientProvider)].
@riverpod
class AuthRepository extends _$AuthRepository {
  final _tokenStorage = const TokenStorage();

  @override
  FutureOr<void> build() {}

  // ---------------------------------------------------------------------------
  // Sign in with Apple (iOS + macOS)
  // ---------------------------------------------------------------------------

  /// Initiates the Sign in with Apple flow and authenticates with the API.
  ///
  /// Presents the native ASAuthorizationController sheet, obtains the identity
  /// token and authorization code, then posts them to [POST /v1/auth/apple].
  Future<AuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (identityToken == null) {
        return const AuthResult.error(
          message: 'Sign in with Apple failed. Please try again.',
        );
      }

      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/auth/apple',
        data: {
          'identityToken': identityToken,
          'authorizationCode': authorizationCode,
        },
      );

      return _handleTokenResponse(response.data, provider: 'apple');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthResult.unauthenticated();
      }
      debugPrint('[AuthRepository] Apple sign-in error: $e');
      return const AuthResult.error(
        message: 'Sign in with Apple failed. Please try again.',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      debugPrint('[AuthRepository] signInWithApple unexpected error: $e');
      return const AuthResult.error(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in with Google
  // ---------------------------------------------------------------------------

  /// Initiates the Google Sign In flow and authenticates with the API.
  ///
  /// On iOS, presents the native Google picker. On macOS, uses a web-based
  /// authentication flow. The package handles platform differences transparently.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in flow.
        return const AuthResult.unauthenticated();
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        return const AuthResult.error(
          message: 'Sign in with Google failed. Please try again.',
        );
      }

      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/auth/google',
        data: {'idToken': idToken},
      );

      return _handleTokenResponse(response.data, provider: 'google');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      debugPrint('[AuthRepository] signInWithGoogle unexpected error: $e');
      return const AuthResult.error(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in with email and password
  // ---------------------------------------------------------------------------

  /// Authenticates the user with email and password.
  ///
  /// On success, stores tokens in the Keychain and returns [AuthResult.authenticated].
  /// When 2FA is enabled, the server returns `{ status: 'totp_required', tempToken }` —
  /// this method returns [AuthResult.twoFactorRequired] with the temp token in that case.
  /// On invalid credentials, returns [AuthResult.error] with a plain-language message.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/auth/email',
        data: {'email': email, 'password': password},
      );

      // Handle 2FA challenge: { status: 'totp_required', tempToken }
      final responseData = response.data?['data'] as Map<String, dynamic>?;
      final status = responseData?['status'] as String?;
      if (status == 'totp_required') {
        final tempToken = responseData?['tempToken'] as String?;
        if (tempToken != null && tempToken.isNotEmpty) {
          return AuthResult.twoFactorRequired(tempToken: tempToken);
        }
        return const AuthResult.error(
          message: 'Something went wrong. Please try again.',
        );
      }

      return _handleTokenResponse(response.data, provider: 'email');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      debugPrint('[AuthRepository] signInWithEmail unexpected error: $e');
      return const AuthResult.error(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Two-factor authentication
  // ---------------------------------------------------------------------------

  /// Completes the 2FA login step by verifying the TOTP code or backup code.
  ///
  /// [tempToken] is the short-lived token returned by [POST /v1/auth/email] when
  /// 2FA is enabled. [totpCode] is the 6-digit TOTP code or a one-time backup code.
  ///
  /// On success, stores full access + refresh tokens and returns [AuthResult.authenticated].
  /// On invalid code, returns [AuthResult.error] (FR92, AC #3).
  Future<AuthResult> verify2FA(String tempToken, String totpCode) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/auth/2fa/verify',
        data: {'tempToken': tempToken, 'code': totpCode},
      );

      return _handleTokenResponse(response.data, provider: 'email');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final errorData = responseData['error'] as Map<String, dynamic>?;
        final code = errorData?['code'] as String?;
        if (code == 'INVALID_TOTP_CODE') {
          return const AuthResult.error(
            message: AppStrings.twoFactorVerifyError,
          );
        }
      }
      debugPrint('[AuthRepository] verify2FA DioException: ${e.message}');
      return const AuthResult.error(
        message: 'Something went wrong. Please try again.',
      );
    } catch (e) {
      debugPrint('[AuthRepository] verify2FA unexpected error: $e');
      return const AuthResult.error(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Clears stored tokens and sets auth state to unauthenticated.
  Future<void> signOut() async {
    await _tokenStorage.clearTokens();
    // Auth state provider is invalidated by the caller (AuthStateNotifier.signOut)
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses a successful auth response, stores tokens, and returns [AuthResult.authenticated].
  ///
  /// [provider] must be 'email', 'apple', or 'google' — used by
  /// [AccountSettingsScreen] to hide the 2FA tile for OAuth users (NFR-S8).
  Future<AuthResult> _handleTokenResponse(
    Map<String, dynamic>? data, {
    required String provider,
  }) async {
    final responseData = data?['data'] as Map<String, dynamic>?;
    final accessToken = responseData?['accessToken'] as String?;
    final refreshToken = responseData?['refreshToken'] as String?;
    final userId = responseData?['userId'] as String?;

    if (accessToken == null || refreshToken == null || userId == null) {
      return const AuthResult.error(
        message: 'Something went wrong. Please try again.',
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return AuthResult.authenticated(userId: userId, provider: provider);
  }

  /// Maps a [DioException] to an [AuthResult.error] with a plain-language message.
  ///
  /// Extracts the server error message from the envelope when available.
  /// Never exposes raw error codes or HTTP status codes to the user (NFR-UX2).
  AuthResult _handleDioError(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final errorData = responseData['error'] as Map<String, dynamic>?;
      final code = errorData?['code'] as String?;

      if (code == 'INVALID_CREDENTIALS') {
        return const AuthResult.error(
          message:
              "That email or password isn't quite right. Try again or reset your password.",
        );
      }
    }

    debugPrint('[AuthRepository] DioException: ${e.message}');
    return const AuthResult.error(
      message: 'Something went wrong. Please try again.',
    );
  }
}
