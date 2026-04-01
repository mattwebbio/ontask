// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides [ProofRepository] with injected [ApiClient] and [AppDatabase].
///
/// keepAlive: true — proof repository must persist across route transitions.

@ProviderFor(proofRepository)
final proofRepositoryProvider = ProofRepositoryProvider._();

/// Provides [ProofRepository] with injected [ApiClient] and [AppDatabase].
///
/// keepAlive: true — proof repository must persist across route transitions.

final class ProofRepositoryProvider
    extends
        $FunctionalProvider<ProofRepository, ProofRepository, ProofRepository>
    with $Provider<ProofRepository> {
  /// Provides [ProofRepository] with injected [ApiClient] and [AppDatabase].
  ///
  /// keepAlive: true — proof repository must persist across route transitions.
  ProofRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proofRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proofRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProofRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProofRepository create(Ref ref) {
    return proofRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProofRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProofRepository>(value),
    );
  }
}

String _$proofRepositoryHash() => r'a4694699c86ca172664ff239be43f16d71f4dbab';
