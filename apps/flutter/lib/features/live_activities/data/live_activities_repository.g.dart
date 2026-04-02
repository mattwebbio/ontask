// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_activities_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(liveActivitiesRepository)
final liveActivitiesRepositoryProvider = LiveActivitiesRepositoryProvider._();

final class LiveActivitiesRepositoryProvider
    extends
        $FunctionalProvider<
          LiveActivitiesRepository,
          LiveActivitiesRepository,
          LiveActivitiesRepository
        >
    with $Provider<LiveActivitiesRepository> {
  LiveActivitiesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveActivitiesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveActivitiesRepositoryHash();

  @$internal
  @override
  $ProviderElement<LiveActivitiesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LiveActivitiesRepository create(Ref ref) {
    return liveActivitiesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveActivitiesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveActivitiesRepository>(value),
    );
  }
}

String _$liveActivitiesRepositoryHash() =>
    r'a4f1c9b2e8d3071f6c5a8e2b9d4f7a3c1e6b8d0f';
