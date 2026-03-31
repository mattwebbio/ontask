// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [NowRepository].

@ProviderFor(nowRepository)
final nowRepositoryProvider = NowRepositoryProvider._();

/// Riverpod provider for [NowRepository].

final class NowRepositoryProvider
    extends $FunctionalProvider<NowRepository, NowRepository, NowRepository>
    with $Provider<NowRepository> {
  /// Riverpod provider for [NowRepository].
  NowRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowRepositoryHash();

  @$internal
  @override
  $ProviderElement<NowRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NowRepository create(Ref ref) {
    return nowRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NowRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NowRepository>(value),
    );
  }
}

String _$nowRepositoryHash() => r'2a131e683b373f10f6e663eced7882a65528b4da';
