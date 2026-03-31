// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_view_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async provider that loads the user's saved [TodayViewMode] from
/// [SharedPreferences].
///
/// Defaults to [TodayViewMode.list] if no preference has been stored.
/// SharedPreferences key: `'today_view_mode'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

@ProviderFor(todayViewMode)
final todayViewModeProvider = TodayViewModeProvider._();

/// Async provider that loads the user's saved [TodayViewMode] from
/// [SharedPreferences].
///
/// Defaults to [TodayViewMode.list] if no preference has been stored.
/// SharedPreferences key: `'today_view_mode'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

final class TodayViewModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodayViewMode>,
          TodayViewMode,
          FutureOr<TodayViewMode>
        >
    with $FutureModifier<TodayViewMode>, $FutureProvider<TodayViewMode> {
  /// Async provider that loads the user's saved [TodayViewMode] from
  /// [SharedPreferences].
  ///
  /// Defaults to [TodayViewMode.list] if no preference has been stored.
  /// SharedPreferences key: `'today_view_mode'`
  ///
  /// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
  TodayViewModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayViewModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayViewModeHash();

  @$internal
  @override
  $FutureProviderElement<TodayViewMode> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TodayViewMode> create(Ref ref) {
    return todayViewMode(ref);
  }
}

String _$todayViewModeHash() => r'09dbd138ada362a82d052df3cfa79b5e8cb0e8da';

/// Write gateway for updating the user's Today tab view mode preference.
///
/// Follows the same read/write gateway pattern as [ThemeSettings] in
/// `theme_provider.dart`. Persists to [SharedPreferences] and invalidates
/// [todayViewModeProvider] so the UI rebuilds immediately.

@ProviderFor(TodayViewModeSettings)
final todayViewModeSettingsProvider = TodayViewModeSettingsProvider._();

/// Write gateway for updating the user's Today tab view mode preference.
///
/// Follows the same read/write gateway pattern as [ThemeSettings] in
/// `theme_provider.dart`. Persists to [SharedPreferences] and invalidates
/// [todayViewModeProvider] so the UI rebuilds immediately.
final class TodayViewModeSettingsProvider
    extends $NotifierProvider<TodayViewModeSettings, void> {
  /// Write gateway for updating the user's Today tab view mode preference.
  ///
  /// Follows the same read/write gateway pattern as [ThemeSettings] in
  /// `theme_provider.dart`. Persists to [SharedPreferences] and invalidates
  /// [todayViewModeProvider] so the UI rebuilds immediately.
  TodayViewModeSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayViewModeSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayViewModeSettingsHash();

  @$internal
  @override
  TodayViewModeSettings create() => TodayViewModeSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$todayViewModeSettingsHash() =>
    r'3bf0d28deebcf2c8b9c2d446bfdd802f6654f688';

/// Write gateway for updating the user's Today tab view mode preference.
///
/// Follows the same read/write gateway pattern as [ThemeSettings] in
/// `theme_provider.dart`. Persists to [SharedPreferences] and invalidates
/// [todayViewModeProvider] so the UI rebuilds immediately.

abstract class _$TodayViewModeSettings extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
