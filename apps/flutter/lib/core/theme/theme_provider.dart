import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'font_channel.dart';

part 'theme_provider.g.dart';

/// Resolved font configuration — holds the serif font family string to use.
///
/// On iOS with New York available: `.NewYorkFont`.
/// All other platforms / fallback: `PlayfairDisplay`.
class FontConfig {
  final String serifFamily;
  const FontConfig({required this.serifFamily});
}

/// Async provider that resolves the platform serif font family at app start.
///
/// Kept alive so the platform channel is only queried once per app session.
@Riverpod(keepAlive: true)
Future<FontConfig> fontConfig(Ref ref) async {
  final newYorkAvailable = await isNewYorkAvailable();
  return FontConfig(
    serifFamily: newYorkAvailable ? '.NewYorkFont' : 'PlayfairDisplay',
  );
}

/// Async provider that loads the user's saved [ThemeVariant] from
/// [SharedPreferences].
///
/// Defaults to [ThemeVariant.clay] if no preference has been stored.
/// The Settings UI (Story 1.10) writes the `theme_variant` key to update this.
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
@Riverpod(keepAlive: true)
Future<ThemeVariant> themeVariant(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('theme_variant');
  return ThemeVariant.values.firstWhere(
    (v) => v.name == stored,
    orElse: () => ThemeVariant.clay,
  );
}

/// Async provider that loads the user's saved [ThemeMode] from
/// [SharedPreferences].
///
/// Defaults to [ThemeMode.system] if no preference has been stored.
/// SharedPreferences key: `'theme_mode'`
/// Values stored as: `'light'`, `'dark'`, `'system'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
@Riverpod(keepAlive: true)
Future<ThemeMode> themeMode(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('theme_mode');
  switch (stored) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Async provider that loads the user's text scale increment from
/// [SharedPreferences].
///
/// The increment is additive: 0.0 = system default, 0.1 = one step,
/// 0.2 = two steps, 0.3 = three steps (NFR-A5: at least three above default).
/// SharedPreferences key: `'theme_text_scale_increment'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
@Riverpod(keepAlive: true)
Future<double> textScaleIncrement(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('theme_text_scale_increment') ?? 0.0;
}

/// Notifier for updating [themeVariant], [themeMode], and [textScaleIncrement].
///
/// Exposes write methods that persist to [SharedPreferences] and invalidate the
/// relevant read provider so the UI rebuilds immediately (no restart required).
@Riverpod(keepAlive: true)
class ThemeSettings extends _$ThemeSettings {
  @override
  void build() {
    // No state — this notifier is purely a write gateway.
  }

  /// Persists the selected [ThemeVariant] and invalidates [themeVariantProvider].
  Future<void> setThemeVariant(ThemeVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_variant', variant.name);
    ref.invalidate(themeVariantProvider);
  }

  /// Persists the selected [ThemeMode] and invalidates [themeModeProvider].
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString('theme_mode', value);
    ref.invalidate(themeModeProvider);
  }

  /// Persists the text scale [increment] and invalidates [textScaleIncrementProvider].
  ///
  /// [increment] must be ≥ 0.0. Each step = 0.1. Three increments above
  /// system default satisfies NFR-A5.
  Future<void> setTextScaleIncrement(double increment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('theme_text_scale_increment', increment);
    ref.invalidate(textScaleIncrementProvider);
  }
}
