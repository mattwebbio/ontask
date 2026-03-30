import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Sealed union representing the result of an authentication operation.
///
/// States:
/// - [AuthResult.authenticated] — user is signed in and tokens are stored
/// - [AuthResult.unauthenticated] — no valid session exists
/// - [AuthResult.error] — an authentication attempt failed with a message
@freezed
sealed class AuthResult with _$AuthResult {
  const factory AuthResult.authenticated({required String userId}) = Authenticated;
  const factory AuthResult.unauthenticated() = Unauthenticated;
  const factory AuthResult.error({required String message}) = AuthError;
}
