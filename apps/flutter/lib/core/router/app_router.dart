import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Root application router.
///
/// Routes are expanded in later stories (1.6 tab shell, 1.7 macOS layout,
/// 1.8 auth). For now a single placeholder route at '/' keeps the app
/// navigable without referencing yet-to-be-built screens.
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        // Placeholder widget — replaced in Story 1.6 (tab bar navigation shell).
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OnTask')),
        ),
      ),
    ],
  );
}
