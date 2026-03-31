// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [ListsRepository].

@ProviderFor(listsRepository)
final listsRepositoryProvider = ListsRepositoryProvider._();

/// Riverpod provider for [ListsRepository].

final class ListsRepositoryProvider
    extends
        $FunctionalProvider<ListsRepository, ListsRepository, ListsRepository>
    with $Provider<ListsRepository> {
  /// Riverpod provider for [ListsRepository].
  ListsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ListsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ListsRepository create(Ref ref) {
    return listsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListsRepository>(value),
    );
  }
}

String _$listsRepositoryHash() => r'670837ef305df9206807f3303311fe20ae3c39ba';
