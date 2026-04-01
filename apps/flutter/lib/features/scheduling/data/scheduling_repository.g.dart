// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduling_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [SchedulingRepository].

@ProviderFor(schedulingRepository)
final schedulingRepositoryProvider = SchedulingRepositoryProvider._();

/// Riverpod provider for [SchedulingRepository].

final class SchedulingRepositoryProvider
    extends
        $FunctionalProvider<
          SchedulingRepository,
          SchedulingRepository,
          SchedulingRepository
        >
    with $Provider<SchedulingRepository> {
  /// Riverpod provider for [SchedulingRepository].
  SchedulingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schedulingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schedulingRepositoryHash();

  @$internal
  @override
  $ProviderElement<SchedulingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SchedulingRepository create(Ref ref) {
    return schedulingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SchedulingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SchedulingRepository>(value),
    );
  }
}

String _$schedulingRepositoryHash() =>
    r'cd245f1447ec51005176093d8b39045d9da9658f';
