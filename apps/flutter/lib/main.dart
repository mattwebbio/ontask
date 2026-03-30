import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: OnTaskApp()));
}

/// Root application widget.
///
/// Uses [ConsumerWidget] so it can watch the Riverpod [appRouterProvider].
/// [MaterialApp.router] is used instead of plain [MaterialApp] to hand routing
/// control to go_router.
class OnTaskApp extends ConsumerWidget {
  const OnTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'OnTask',
      routerConfig: router,
    );
  }
}
