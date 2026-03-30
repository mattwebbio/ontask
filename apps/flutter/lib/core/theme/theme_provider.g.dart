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
