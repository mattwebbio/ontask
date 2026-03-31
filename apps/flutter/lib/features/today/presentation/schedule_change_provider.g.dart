// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_change_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the schedule changes from the API.

@ProviderFor(scheduleChanges)
final scheduleChangesProvider = ScheduleChangesProvider._();

/// Fetches the schedule changes from the API.

final class ScheduleChangesProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScheduleChanges>,
          ScheduleChanges,
          FutureOr<ScheduleChanges>
        >
    with $FutureModifier<ScheduleChanges>, $FutureProvider<ScheduleChanges> {
  /// Fetches the schedule changes from the API.
  ScheduleChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleChangesHash();

  @$internal
  @override
  $FutureProviderElement<ScheduleChanges> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScheduleChanges> create(Ref ref) {
    return scheduleChanges(ref);
  }
}

String _$scheduleChangesHash() => r'96d5eb25b70aa8ace28ee445b13af85f600cf4a9';

/// Manages visibility of the Schedule Change Banner.
///
/// Starts as loading, then resolves to [true] if there are meaningful changes.
/// Calling [dismiss] hides the banner for the current session.

@ProviderFor(ScheduleChangeBannerVisible)
final scheduleChangeBannerVisibleProvider =
    ScheduleChangeBannerVisibleProvider._();

/// Manages visibility of the Schedule Change Banner.
///
/// Starts as loading, then resolves to [true] if there are meaningful changes.
/// Calling [dismiss] hides the banner for the current session.
final class ScheduleChangeBannerVisibleProvider
    extends $AsyncNotifierProvider<ScheduleChangeBannerVisible, bool> {
  /// Manages visibility of the Schedule Change Banner.
  ///
  /// Starts as loading, then resolves to [true] if there are meaningful changes.
  /// Calling [dismiss] hides the banner for the current session.
  ScheduleChangeBannerVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleChangeBannerVisibleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleChangeBannerVisibleHash();

  @$internal
  @override
  ScheduleChangeBannerVisible create() => ScheduleChangeBannerVisible();
}

String _$scheduleChangeBannerVisibleHash() =>
    r'a3b802aaa3e3cf96c16e46bf613a06526ea2467a';

/// Manages visibility of the Schedule Change Banner.
///
/// Starts as loading, then resolves to [true] if there are meaningful changes.
/// Calling [dismiss] hides the banner for the current session.

abstract class _$ScheduleChangeBannerVisible extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
