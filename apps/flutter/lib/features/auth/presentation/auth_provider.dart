import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import '../domain/auth_result.dart';

part 'auth_provider.g.dart';

/// Manages the current authentication state of the app.
///
/// Initialises by checking whether a stored access token exists in the Keychain.
/// If a token is found, it assumes the user is authenticated — token validity
/// is confirmed lazily by the 401 interceptor on the first API call.
///
/// [AuthInterceptor._forceSignOut] calls [setUnauthenticated] via the callback
/// injected into [ApiClient] when token refresh fails irreversibly.
@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthResult build() {
    // Synchronous initialisation — start as unauthenticated and then
    // perform async token check below.
    _initFromStorage();
    return const AuthResult.unauthenticated();
  }

  /// Reads the stored access token asynchronously and updates state if present.
  Future<void> _initFromStorage() async {
    final token = await const TokenStorage().getAccessToken();
    if (token != null && token.isNotEmpty) {
      // Assume authenticated — the 401 interceptor will sign-out if the token
      // is actually expired and the refresh attempt fails.
      state = const AuthResult.authenticated(userId: '');
    }
  }

  /// Called on successful authentication to update state.
  void setAuthenticated(String userId) {
    state = AuthResult.authenticated(userId: userId);
  }

  /// Called on sign-out or when the 401 interceptor forces the user out.
  void setUnauthenticated() {
    state = const AuthResult.unauthenticated();
  }

  /// Signs out the current user: clears tokens and resets state.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider.notifier).signOut();
    setUnauthenticated();
  }
}

