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
        $FunctionalProvider<SchedulingRepository, SchedulingRepository, SchedulingRepository>
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
  $ProviderElement<SchedulingRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

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

String _$schedulingRepositoryHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';
