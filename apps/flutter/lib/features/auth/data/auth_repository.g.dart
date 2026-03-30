// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository responsible for all authentication flows.
///
/// Injected via Riverpod — never instantiate directly (breaks test overrides).
/// Depends on [ApiClient] via [ref.watch(apiClientProvider)].

@ProviderFor(AuthRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Repository responsible for all authentication flows.
///
/// Injected via Riverpod — never instantiate directly (breaks test overrides).
/// Depends on [ApiClient] via [ref.watch(apiClientProvider)].
final class AuthRepositoryProvider
    extends $AsyncNotifierProvider<AuthRepository, void> {
  /// Repository responsible for all authentication flows.
  ///
  /// Injected via Riverpod — never instantiate directly (breaks test overrides).
  /// Depends on [ApiClient] via [ref.watch(apiClientProvider)].
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  AuthRepository create() => AuthRepository();
}

String _$authRepositoryHash() => r'e1d823c832464751dcc2135668e0eba001b43fae';

/// Repository responsible for all authentication flows.
///
/// Injected via Riverpod — never instantiate directly (breaks test overrides).
/// Depends on [ApiClient] via [ref.watch(apiClientProvider)].

abstract class _$AuthRepository extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
