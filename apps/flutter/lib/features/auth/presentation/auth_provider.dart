import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import '../domain/auth_result.dart';

part 'auth_provider.g.dart';

/// SharedPreferences key for the lightweight auth-hint boolean.
///
/// Set to `true` on successful sign-in, `false` on sign-out.
/// Allows [AuthStateNotifier.build] to return a synchronous initial state
/// without waiting for the Keychain, eliminating the flash-to-sign-in race.
const kAuthWasAuthenticated = 'auth_was_authenticated';

/// Manages the current authentication state of the app.
///
/// Initialises synchronously from a pre-loaded [SharedPreferences] hint
/// (`auth_was_authenticated`) so the router never briefly redirects a
/// returning user to the sign-in screen.  [_initFromStorage] then validates
/// the actual Keychain token asynchronously and corrects state if the token
/// is missing or expired.
///
/// [AuthInterceptor._forceSignOut] calls [setUnauthenticated] via the callback
/// injected into [ApiClient] when token refresh fails irreversibly.
///
/// keepAlive: prevents the disposed-notifier problem where [ApiClient] holds a
/// stale [setUnauthenticated] reference after auto-dispose recreates the
/// provider.
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  /// Pre-warmed [SharedPreferences] instance, set by [main] before [runApp].
  ///
  /// Keeping it static allows synchronous access inside [build()] without
  /// an `await`.  In tests, override with [prewarmPrefs] or it falls back to
  /// treating the user as unauthenticated.
  static SharedPreferences? _prefs;

  /// Called from [main] after `SharedPreferences.getInstance()` resolves so
  /// that [build()] can read [kAuthWasAuthenticated] synchronously.
  static void prewarmPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  @override
  AuthResult build() {
    // Synchronous initial state based on the lightweight preference hint.
    // This prevents the router from flashing to /auth/sign-in for returning
    // users while the Keychain read is still in progress.
    final wasAuthenticated = _prefs?.getBool(kAuthWasAuthenticated) ?? false;

    // Kick off the real Keychain validation asynchronously.
    _initFromStorage();

    return wasAuthenticated
        ? const AuthResult.authenticated(userId: '')
        : const AuthResult.unauthenticated();
  }

  /// Validates the stored Keychain token and corrects state if needed.
  ///
  /// If no valid token is found the state is set to unauthenticated (even if
  /// the preference hint said the user was authenticated), and the preference
  /// is cleared to keep the hint consistent.
  Future<void> _initFromStorage() async {
    final token = await const TokenStorage().getAccessToken();
    if (token != null && token.isNotEmpty) {
      // Assume authenticated — the 401 interceptor will sign-out if the token
      // is actually expired and the refresh attempt fails.
      state = const AuthResult.authenticated(userId: '');
    } else {
      // No token in Keychain — ensure we are unauthenticated and reset the
      // hint so next launch starts unauthenticated too.
      state = const AuthResult.unauthenticated();
      await _prefs?.setBool(kAuthWasAuthenticated, false);
    }
  }

  /// Called on successful authentication to update state.
  Future<void> setAuthenticated(String userId) async {
    await _prefs?.setBool(kAuthWasAuthenticated, true);
    state = AuthResult.authenticated(userId: userId);
  }

  /// Called on sign-out or when the 401 interceptor forces the user out.
  Future<void> setUnauthenticated() async {
    await _prefs?.setBool(kAuthWasAuthenticated, false);
    state = const AuthResult.unauthenticated();
  }

  /// Signs out the current user: clears tokens and resets state.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider.notifier).signOut();
    await setUnauthenticated();
  }
}
