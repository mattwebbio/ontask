// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment_contracts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [CommitmentContractsRepository].

@ProviderFor(commitmentContractsRepository)
final commitmentContractsRepositoryProvider =
    CommitmentContractsRepositoryProvider._();

/// Riverpod provider for [CommitmentContractsRepository].

final class CommitmentContractsRepositoryProvider
    extends
        $FunctionalProvider<
          CommitmentContractsRepository,
          CommitmentContractsRepository,
          CommitmentContractsRepository
        >
    with $Provider<CommitmentContractsRepository> {
  /// Riverpod provider for [CommitmentContractsRepository].
  CommitmentContractsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commitmentContractsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commitmentContractsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CommitmentContractsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommitmentContractsRepository create(Ref ref) {
    return commitmentContractsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommitmentContractsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommitmentContractsRepository>(
        value,
      ),
    );
  }
}

String _$commitmentContractsRepositoryHash() =>
    r'40ebc5f009edb89938a1d906d47be3b217d9501d';
