import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/auth_result.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/lists/presentation/lists_screen.dart';
import '../../features/now/presentation/now_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/today/presentation/today_screen.dart';

part 'app_router.g.dart';

/// Root application router.
///
/// Uses [StatefulShellRoute.indexedStack] (go_router ≥ 7.x, currently 15.1.x)
/// to preserve each tab's navigation state independently.
///
/// Tab branches: Now (/now), Today (/today), Add (/add — stub), Lists (/lists)
/// The Add branch is a stub; [AppShell] intercepts the tap before any navigation
/// occurs and opens [AddTabSheet] instead.
///
/// The `/auth/sign-in` route is a TOP-LEVEL route — NOT inside [StatefulShellRoute].
/// This ensures the auth screen renders without the shell (no tab bar, no sidebar).
@riverpod
GoRouter appRouter(Ref ref) {
  // AuthStateListenable bridges Riverpod auth state changes to GoRouter's
  // refreshListenable so redirects fire automatically on sign-in / sign-out.
  final authListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/now',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState is Authenticated;
      final isOnAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isOnAuthRoute) return '/auth/sign-in';
      if (isAuthenticated && isOnAuthRoute) return '/now';
      return null;
    },
    routes: [
      // Auth route — outside StatefulShellRoute so no shell renders over it.
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const AuthScreen(),
      ),

      // Main app shell — all authenticated routes live inside here.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/now',
                builder: (context, state) => const NowScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          // Add branch — stub; AppShell intercepts tap before navigation occurs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/lists',
                builder: (context, state) => const ListsScreen(),
              ),
            ],
          ),
          // Settings branch — macOS sidebar item 3 (index 4).
          // iOS shell never navigates to this branch.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridges [authStateProvider] changes to [GoRouter.refreshListenable].
///
/// GoRouter requires a [Listenable] to re-evaluate its [redirect] callback.
/// This [ChangeNotifier] subscribes to the Riverpod auth provider and calls
/// [notifyListeners] whenever authentication state changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (prev, next) {
      notifyListeners();
    });
  }
}
