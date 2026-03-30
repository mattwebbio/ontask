import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: OnTaskApp()));
}

/// Root application widget.
///
/// Uses [ConsumerWidget] so it can watch the Riverpod [appRouterProvider],
/// [themeVariantProvider], and [fontConfigProvider].
/// [MaterialApp.router] is used to hand routing control to go_router.
///
/// Theme defaults to [ThemeVariant.clay] while preferences load
/// (via `valueOrNull`) — ensures no blank screen during async init.
class OnTaskApp extends ConsumerWidget {
  const OnTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final variantAsync = ref.watch(themeVariantProvider);
    final fontAsync = ref.watch(fontConfigProvider);

    final variant = variantAsync.value ?? ThemeVariant.clay;
    final fontConfig =
        fontAsync.value ?? const FontConfig(serifFamily: 'PlayfairDisplay');

    return MaterialApp.router(
      title: 'OnTask',
      routerConfig: router,
      theme: AppTheme.light(variant, fontConfig.serifFamily),
      darkTheme: AppTheme.dark(variant, fontConfig.serifFamily),
      themeMode: ThemeMode.system,
    );
  }
}
