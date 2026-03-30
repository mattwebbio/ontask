// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async provider that resolves the platform serif font family at app start.
///
/// Kept alive so the platform channel is only queried once per app session.

@ProviderFor(fontConfig)
final fontConfigProvider = FontConfigProvider._();

/// Async provider that resolves the platform serif font family at app start.
///
/// Kept alive so the platform channel is only queried once per app session.

final class FontConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<FontConfig>,
          FontConfig,
          FutureOr<FontConfig>
        >
    with $FutureModifier<FontConfig>, $FutureProvider<FontConfig> {
  /// Async provider that resolves the platform serif font family at app start.
  ///
  /// Kept alive so the platform channel is only queried once per app session.
  FontConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontConfigHash();

  @$internal
  @override
  $FutureProviderElement<FontConfig> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FontConfig> create(Ref ref) {
    return fontConfig(ref);
  }
}

String _$fontConfigHash() => r'73c0ce9495a80bb0c9c75c0c453c8ab4277d466d';

/// Async provider that loads the user's saved [ThemeVariant] from
/// [SharedPreferences].
///
/// Defaults to [ThemeVariant.clay] if no preference has been stored.
/// The Settings UI (Story 1.10) writes the `theme_variant` key to update this.
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

@ProviderFor(themeVariant)
final themeVariantProvider = ThemeVariantProvider._();

/// Async provider that loads the user's saved [ThemeVariant] from
/// [SharedPreferences].
///
/// Defaults to [ThemeVariant.clay] if no preference has been stored.
/// The Settings UI (Story 1.10) writes the `theme_variant` key to update this.
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

final class ThemeVariantProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemeVariant>,
          ThemeVariant,
          FutureOr<ThemeVariant>
        >
    with $FutureModifier<ThemeVariant>, $FutureProvider<ThemeVariant> {
  /// Async provider that loads the user's saved [ThemeVariant] from
  /// [SharedPreferences].
  ///
  /// Defaults to [ThemeVariant.clay] if no preference has been stored.
  /// The Settings UI (Story 1.10) writes the `theme_variant` key to update this.
  ///
  /// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
  ThemeVariantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeVariantProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeVariantHash();

  @$internal
  @override
  $FutureProviderElement<ThemeVariant> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ThemeVariant> create(Ref ref) {
    return themeVariant(ref);
  }
}

String _$themeVariantHash() => r'867a7e8bc9ee9f4382aaa9d22ea2b1709d4e56e8';

/// Async provider that loads the user's saved [ThemeMode] from
/// [SharedPreferences].
///
/// Defaults to [ThemeMode.system] if no preference has been stored.
/// SharedPreferences key: `'theme_mode'`
/// Values stored as: `'light'`, `'dark'`, `'system'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

/// Async provider that loads the user's saved [ThemeMode] from
/// [SharedPreferences].
///
/// Defaults to [ThemeMode.system] if no preference has been stored.
/// SharedPreferences key: `'theme_mode'`
/// Values stored as: `'light'`, `'dark'`, `'system'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

final class ThemeModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemeMode>,
          ThemeMode,
          FutureOr<ThemeMode>
        >
    with $FutureModifier<ThemeMode>, $FutureProvider<ThemeMode> {
  /// Async provider that loads the user's saved [ThemeMode] from
  /// [SharedPreferences].
  ///
  /// Defaults to [ThemeMode.system] if no preference has been stored.
  /// SharedPreferences key: `'theme_mode'`
  /// Values stored as: `'light'`, `'dark'`, `'system'`
  ///
  /// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $FutureProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ThemeMode> create(Ref ref) {
    return themeMode(ref);
  }
}

String _$themeModeHash() => r'9164c422e5a5fc330b8e90a47856de2c2c43c19b';

/// Async provider that loads the user's text scale increment from
/// [SharedPreferences].
///
/// The increment is additive: 0.0 = system default, 0.1 = one step,
/// 0.2 = two steps, 0.3 = three steps (NFR-A5: at least three above default).
/// SharedPreferences key: `'theme_text_scale_increment'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

@ProviderFor(textScaleIncrement)
final textScaleIncrementProvider = TextScaleIncrementProvider._();

/// Async provider that loads the user's text scale increment from
/// [SharedPreferences].
///
/// The increment is additive: 0.0 = system default, 0.1 = one step,
/// 0.2 = two steps, 0.3 = three steps (NFR-A5: at least three above default).
/// SharedPreferences key: `'theme_text_scale_increment'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.

final class TextScaleIncrementProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Async provider that loads the user's text scale increment from
  /// [SharedPreferences].
  ///
  /// The increment is additive: 0.0 = system default, 0.1 = one step,
  /// 0.2 = two steps, 0.3 = three steps (NFR-A5: at least three above default).
  /// SharedPreferences key: `'theme_text_scale_increment'`
  ///
  /// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
  TextScaleIncrementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textScaleIncrementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textScaleIncrementHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return textScaleIncrement(ref);
  }
}

String _$textScaleIncrementHash() =>
    r'5eb1b5349bcaa0328939ee6c4b96ba79ea5e8320';

/// Notifier for updating [themeVariant], [themeMode], and [textScaleIncrement].
///
/// Exposes write methods that persist to [SharedPreferences] and invalidate the
/// relevant read provider so the UI rebuilds immediately (no restart required).

@ProviderFor(ThemeSettings)
final themeSettingsProvider = ThemeSettingsProvider._();

/// Notifier for updating [themeVariant], [themeMode], and [textScaleIncrement].
///
/// Exposes write methods that persist to [SharedPreferences] and invalidate the
/// relevant read provider so the UI rebuilds immediately (no restart required).
final class ThemeSettingsProvider
    extends $NotifierProvider<ThemeSettings, void> {
  /// Notifier for updating [themeVariant], [themeMode], and [textScaleIncrement].
  ///
  /// Exposes write methods that persist to [SharedPreferences] and invalidate the
  /// relevant read provider so the UI rebuilds immediately (no restart required).
  ThemeSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSettingsHash();

  @$internal
  @override
  ThemeSettings create() => ThemeSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$themeSettingsHash() => r'211984923ed709cb21dbf4c0f3ad0e1568841825';

/// Notifier for updating [themeVariant], [themeMode], and [textScaleIncrement].
///
/// Exposes write methods that persist to [SharedPreferences] and invalidate the
/// relevant read provider so the UI rebuilds immediately (no restart required).

abstract class _$ThemeSettings extends $Notifier<void> {
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
