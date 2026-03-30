import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm SharedPreferences so AuthStateNotifier.build() can read the
  // 'auth_was_authenticated' flag synchronously on first access.
  final prefs = await SharedPreferences.getInstance();
  AuthStateNotifier.prewarmPrefs(prefs);

  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      minimumSize: Size(900, 600),
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
  }
  runApp(const ProviderScope(child: OnTaskApp()));
}

/// Root application widget.
///
/// Uses [ConsumerWidget] so it can watch the Riverpod [appRouterProvider],
/// [themeVariantProvider], [themeModeProvider], [textScaleIncrementProvider],
/// and [fontConfigProvider].
/// [MaterialApp.router] is used to hand routing control to go_router.
///
/// Theme defaults to [ThemeVariant.clay] / [ThemeMode.system] while preferences
/// load (via `valueOrNull`) — ensures no blank screen during async init.
class OnTaskApp extends ConsumerWidget {
  const OnTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final variantAsync = ref.watch(themeVariantProvider);
    final fontAsync = ref.watch(fontConfigProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final textScaleAsync = ref.watch(textScaleIncrementProvider);

    final variant = variantAsync.value ?? ThemeVariant.clay;
    final fontConfig =
        fontAsync.value ?? const FontConfig(serifFamily: 'PlayfairDisplay');
    final themeMode = themeModeAsync.value ?? ThemeMode.system;
    final textScaleIncrement = textScaleAsync.value ?? 0.0;

    return MaterialApp.router(
      title: 'OnTask',
      routerConfig: router,
      theme: AppTheme.light(variant, fontConfig.serifFamily),
      darkTheme: AppTheme.dark(variant, fontConfig.serifFamily),
      themeMode: themeMode,
      // Apply text scale increment — additive factor, clamped to [1.0, 3.0].
      // Three increments above system default (each 0.1) satisfies NFR-A5.
      builder: (context, child) {
        final currentScale = MediaQuery.of(context).textScaler;
        final newScale = TextScaler.linear(
          (currentScale.scale(1.0) + textScaleIncrement).clamp(1.0, 3.0),
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: newScale),
          child: child!,
        );
      },
    );
  }
}
