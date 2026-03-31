// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sections_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [SectionsRepository].

@ProviderFor(sectionsRepository)
final sectionsRepositoryProvider = SectionsRepositoryProvider._();

/// Riverpod provider for [SectionsRepository].

final class SectionsRepositoryProvider
    extends
        $FunctionalProvider<
          SectionsRepository,
          SectionsRepository,
          SectionsRepository
        >
    with $Provider<SectionsRepository> {
  /// Riverpod provider for [SectionsRepository].
  SectionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sectionsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sectionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SectionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SectionsRepository create(Ref ref) {
    return sectionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SectionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SectionsRepository>(value),
    );
  }
}

String _$sectionsRepositoryHash() =>
    r'e0a2d61f1719af519ec0f0c51294be59da4d5821';
