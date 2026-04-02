// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscriptions_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

String _$subscriptionsRepositoryHash() => r'impl(9.1):placeholder';

@ProviderFor(subscriptionsRepository)
final subscriptionsRepositoryProvider = SubscriptionsRepositoryProvider._();

final class SubscriptionsRepositoryProvider
    extends $FunctionalProvider<
      SubscriptionsRepository,
      SubscriptionsRepository,
      SubscriptionsRepository
    >
    with $Provider<SubscriptionsRepository> {
  SubscriptionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionsRepository create(Ref ref) {
    return subscriptionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionsRepository>(value),
    );
  }
}
