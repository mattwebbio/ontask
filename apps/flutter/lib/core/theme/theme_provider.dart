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
@riverpod
Future<ThemeVariant> themeVariant(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('theme_variant');
  return ThemeVariant.values.firstWhere(
    (v) => v.name == stored,
    orElse: () => ThemeVariant.clay,
  );
}
