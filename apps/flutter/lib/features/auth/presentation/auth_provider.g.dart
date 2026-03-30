// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AuthStateNotifier)
final authStateProvider = AuthStateNotifierProvider._();

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
final class AuthStateNotifierProvider
    extends $NotifierProvider<AuthStateNotifier, AuthResult> {
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
  AuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateNotifierHash();

  @$internal
  @override
  AuthStateNotifier create() => AuthStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthResult value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthResult>(value),
    );
  }
}

String _$authStateNotifierHash() => r'c65a145e23d4636978650eb76927b405571f235a';

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

abstract class _$AuthStateNotifier extends $Notifier<AuthResult> {
  AuthResult build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthResult, AuthResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthResult, AuthResult>,
              AuthResult,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
