// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overbooking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the overbooking status from the API.

@ProviderFor(overbookingStatus)
final overbookingStatusProvider = OverbookingStatusProvider._();

/// Fetches the overbooking status from the API.

final class OverbookingStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<OverbookingStatus>,
          OverbookingStatus,
          FutureOr<OverbookingStatus>
        >
    with
        $FutureModifier<OverbookingStatus>,
        $FutureProvider<OverbookingStatus> {
  /// Fetches the overbooking status from the API.
  OverbookingStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overbookingStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overbookingStatusHash();

  @$internal
  @override
  $FutureProviderElement<OverbookingStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OverbookingStatus> create(Ref ref) {
    return overbookingStatus(ref);
  }
}

String _$overbookingStatusHash() => r'77534019c65fb8c824d42e8f85d22934e8b1ef38';

/// Manages whether the Overbooking Warning Banner has been dismissed.
///
/// Default [false] — banner is visible (if overbooked). Calling [dismiss]
/// hides the banner for the current session.

@ProviderFor(OverbookingBannerDismissed)
final overbookingBannerDismissedProvider =
    OverbookingBannerDismissedProvider._();

/// Manages whether the Overbooking Warning Banner has been dismissed.
///
/// Default [false] — banner is visible (if overbooked). Calling [dismiss]
/// hides the banner for the current session.
final class OverbookingBannerDismissedProvider
    extends $NotifierProvider<OverbookingBannerDismissed, bool> {
  /// Manages whether the Overbooking Warning Banner has been dismissed.
  ///
  /// Default [false] — banner is visible (if overbooked). Calling [dismiss]
  /// hides the banner for the current session.
  OverbookingBannerDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overbookingBannerDismissedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overbookingBannerDismissedHash();

  @$internal
  @override
  OverbookingBannerDismissed create() => OverbookingBannerDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$overbookingBannerDismissedHash() =>
    r'03dd6df49610108dcedd70fa17912e9e0880b59f';

/// Manages whether the Overbooking Warning Banner has been dismissed.
///
/// Default [false] — banner is visible (if overbooked). Calling [dismiss]
/// hides the banner for the current session.

abstract class _$OverbookingBannerDismissed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
