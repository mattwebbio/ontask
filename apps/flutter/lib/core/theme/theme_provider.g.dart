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

String _$fontConfigHash() => r'552fa38bd5575f7bf5eb4ac3d4f1b81f184299e1';

/// Async provider that loads the user's saved [ThemeVariant] from
/// [SharedPreferences].
///
/// Defaults to [ThemeVariant.clay] if no preference has been stored.
/// The Settings UI (Story 1.10) writes the `theme_variant` key to update this.

@ProviderFor(themeVariant)
final themeVariantProvider = ThemeVariantProvider._();

/// Async provider that loads the user's saved [ThemeVariant] from
/// [SharedPreferences].
///
/// Defaults to [ThemeVariant.clay] if no preference has been stored.
/// The Settings UI (Story 1.10) writes the `theme_variant` key to update this.

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
  ThemeVariantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeVariantProvider',
        isAutoDispose: true,
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

String _$themeVariantHash() => r'97fb861b6c5295203bc43d4c585f6cf9a31bb734';
