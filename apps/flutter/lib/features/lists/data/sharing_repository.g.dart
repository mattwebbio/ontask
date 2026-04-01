// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sharing_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [SharingRepository].

@ProviderFor(sharingRepository)
final sharingRepositoryProvider = SharingRepositoryProvider._();

/// Riverpod provider for [SharingRepository].

final class SharingRepositoryProvider
    extends
        $FunctionalProvider<SharingRepository, SharingRepository, SharingRepository>
    with $Provider<SharingRepository> {
  /// Riverpod provider for [SharingRepository].
  SharingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharingRepositoryHash();

  @$internal
  @override
  $ProviderElement<SharingRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharingRepository create(Ref ref) {
    return sharingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharingRepository>(value),
    );
  }
}

String _$sharingRepositoryHash() => r'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
