// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the current authentication state of the app.
///
/// Initialises by checking whether a stored access token exists in the Keychain.
/// If a token is found, it assumes the user is authenticated — token validity
/// is confirmed lazily by the 401 interceptor on the first API call.
///
/// [AuthInterceptor._forceSignOut] calls [setUnauthenticated] via the callback
/// injected into [ApiClient] when token refresh fails irreversibly.

@ProviderFor(AuthStateNotifier)
final authStateProvider = AuthStateNotifierProvider._();

/// Manages the current authentication state of the app.
///
/// Initialises by checking whether a stored access token exists in the Keychain.
/// If a token is found, it assumes the user is authenticated — token validity
/// is confirmed lazily by the 401 interceptor on the first API call.
///
/// [AuthInterceptor._forceSignOut] calls [setUnauthenticated] via the callback
/// injected into [ApiClient] when token refresh fails irreversibly.
final class AuthStateNotifierProvider
    extends $NotifierProvider<AuthStateNotifier, AuthResult> {
  /// Manages the current authentication state of the app.
  ///
  /// Initialises by checking whether a stored access token exists in the Keychain.
  /// If a token is found, it assumes the user is authenticated — token validity
  /// is confirmed lazily by the 401 interceptor on the first API call.
  ///
  /// [AuthInterceptor._forceSignOut] calls [setUnauthenticated] via the callback
  /// injected into [ApiClient] when token refresh fails irreversibly.
  AuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
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

String _$authStateNotifierHash() => r'6286f5671ab3435d602c770b9baa14574e98996a';

/// Manages the current authentication state of the app.
///
/// Initialises by checking whether a stored access token exists in the Keychain.
/// If a token is found, it assumes the user is authenticated — token validity
/// is confirmed lazily by the 401 interceptor on the first API call.
///
/// [AuthInterceptor._forceSignOut] calls [setUnauthenticated] via the callback
/// injected into [ApiClient] when token refresh fails irreversibly.

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
