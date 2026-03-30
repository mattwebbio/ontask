import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Sealed union representing the result of an authentication operation.
///
/// States:
/// - [AuthResult.authenticated] — user is signed in and tokens are stored
/// - [AuthResult.unauthenticated] — no valid session exists
/// - [AuthResult.error] — an authentication attempt failed with a message
/// - [AuthResult.twoFactorRequired] — email login succeeded but 2FA challenge required (FR92)
@freezed
sealed class AuthResult with _$AuthResult {
  const factory AuthResult.authenticated({
    required String userId,
    required String provider,
  }) = Authenticated;
  const factory AuthResult.unauthenticated() = Unauthenticated;
  const factory AuthResult.error({required String message}) = AuthError;

  /// Returned when email/password sign-in succeeds but the account has 2FA enabled.
  ///
  /// The [tempToken] is a short-lived token used to complete the TOTP verification
  /// step via [POST /v1/auth/2fa/verify]. It expires quickly and cannot be used
  /// for general API access (FR92, AC #3).
  const factory AuthResult.twoFactorRequired({
    required String tempToken,
  }) = TwoFactorRequired;
}
