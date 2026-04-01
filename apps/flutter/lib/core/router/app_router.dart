import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/auth_result.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/chapter_break/presentation/chapter_break_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/two_factor_verify_screen.dart';
import '../../features/lists/presentation/accept_invitation_screen.dart';
import '../../features/lists/presentation/list_detail_screen.dart';
import '../../features/lists/presentation/list_settings_screen.dart';
import '../../features/lists/presentation/lists_screen.dart';
import '../../features/now/presentation/now_screen.dart';
import '../../features/onboarding/presentation/onboarding_flow.dart';
import '../../features/commitment_contracts/presentation/impact_dashboard_screen.dart';
import '../../features/settings/presentation/account_settings_screen.dart';
import '../../features/settings/presentation/delete_account_screen.dart';
import '../../features/settings/presentation/export_data_screen.dart';
import '../../features/settings/presentation/farewell_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/two_factor_setup_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/today/presentation/task_detail_stub_screen.dart';
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
      final isTwoFactorRequired = authState is TwoFactorRequired;
      final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
      final isOnFarewellRoute = state.matchedLocation == '/farewell';

      // 2FA challenge — redirect to verify screen (FR92, AC #3).
      if (isTwoFactorRequired && state.matchedLocation != '/auth/2fa-verify') {
        return '/auth/2fa-verify';
      }

      // Farewell screen is accessible post-deletion even when unauthenticated.
      if (isOnFarewellRoute) return null;

      if (!isAuthenticated && !isTwoFactorRequired && !isOnAuthRoute) return '/auth/sign-in';
      if (isAuthenticated && isOnAuthRoute) return '/now';

      // Onboarding gate (only for authenticated users):
      // isOnboardingCompleted is read from the notifier.  In test environments
      // where authStateProvider is overridden with a plain value (not a notifier),
      // the .notifier accessor will throw — fall back to the static prefs accessor
      // which reads directly from the pre-warmed SharedPreferences instance.
      bool onboardingCompleted;
      try {
        onboardingCompleted = ref.read(authStateProvider.notifier).isOnboardingCompleted;
      } catch (_) {
        // Value override in tests: fall back to static prefs read.
        // Tests that want to bypass the onboarding gate must either:
        //   a) Use the real notifier with prewarmPrefs({'onboarding_completed': true}), or
        //   b) Set SharedPreferences.setMockInitialValues({'onboarding_completed': true})
        //      and call AuthStateNotifier.prewarmPrefs(prefs) in setUp.
        onboardingCompleted = AuthStateNotifier.isOnboardingCompletedFromPrefs;
      }
      if (isAuthenticated && !onboardingCompleted && !isOnOnboardingRoute) {
        return '/onboarding';
      }
      if (isAuthenticated && onboardingCompleted && isOnOnboardingRoute) {
        return '/now';
      }

      return null;
    },
    routes: [
      // Auth route — outside StatefulShellRoute so no shell renders over it.
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const AuthScreen(),
      ),

      // 2FA verification route — step 2 of email login when 2FA is enabled (FR92).
      // Not inside the authenticated shell — rendered without tab bar.
      GoRoute(
        path: '/auth/2fa-verify',
        builder: (context, state) {
          final authState = ref.read(authStateProvider);
          final tempToken = (authState is TwoFactorRequired)
              ? authState.tempToken
              : '';
          return TwoFactorVerifyScreen(tempToken: tempToken);
        },
      ),

      // Farewell route — terminal screen after account deletion (FR60).
      // Outside authenticated shell — accessible without auth state.
      GoRoute(
        path: '/farewell',
        builder: (context, state) => const FarewellScreen(),
      ),

      // Onboarding route — outside StatefulShellRoute so no shell renders over it.
      // Same pattern as /auth/sign-in (Story 1.8).
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),

      // Invitation accept screen — top-level route (no shell chrome / tab bar).
      // Reached via deep link: /invitation/:token (FR16).
      // Unauthenticated recipients will be redirected to /auth/sign-in first,
      // then must re-open the link after authentication (stub V1 behaviour).
      GoRoute(
        path: '/invitation/:token',
        builder: (context, state) => AcceptInvitationScreen(
          token: state.pathParameters['token']!,
        ),
      ),

      // Chapter Break Screen — top-level route (no shell chrome / tab bar).
      // Shown after significant milestones: task completed, commitment locked,
      // missed commitment recovery (UX-DR13). Navigate here via:
      //   context.push('/chapter-break', extra: {'taskTitle': ..., 'stakeAmount': ...})
      // [onContinue] calls context.go('/now') for a clean stack.
      //
      // TODO(v1.1-ipad): When implementing two-column iPad layout, add a
      // LayoutBuilder breakpoint check at 600pt logical width in AppShell.
      // Below 600pt → phone layout (current). Above 600pt → two-column:
      // sidebar (240pt fixed) + content (fills). Touch-optimised — not macOS
      // sidebar semantics. No architectural changes required; clean upgrade path.
      GoRoute(
        path: '/chapter-break',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChapterBreakScreen(
            taskTitle: extra?['taskTitle'] as String? ?? '',
            stakeAmount: extra?['stakeAmount'] as String?,
            onContinue: () => context.go('/now'),
          );
        },
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
                routes: [
                  // Task detail stub — navigated from timeline task block tap (AC3, FR79).
                  // Full task detail UI is a later story; this stub shows the task ID.
                  GoRoute(
                    path: 'tasks/:id',
                    builder: (context, state) => TaskDetailStubScreen(
                      taskId: state.pathParameters['id']!,
                    ),
                  ),
                ],
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
                routes: [
                  // IMPORTANT: /lists/:id/settings MUST be registered BEFORE /lists/:id
                  // to avoid GoRouter matching "settings" as a list ID.
                  GoRoute(
                    path: ':id/settings',
                    builder: (context, state) => ListSettingsScreen(
                      listId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ListDetailScreen(
                      listId: state.pathParameters['id']!,
                    ),
                  ),
                ],
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
                routes: [
                  // Account sub-screen (Story 1.11).
                  GoRoute(
                    path: 'account',
                    builder: (context, state) =>
                        const AccountSettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'export',
                        builder: (context, state) =>
                            const ExportDataScreen(),
                      ),
                      GoRoute(
                        path: 'delete',
                        builder: (context, state) =>
                            const DeleteAccountScreen(),
                      ),
                      GoRoute(
                        path: '2fa-setup',
                        builder: (context, state) =>
                            const TwoFactorSetupScreen(),
                      ),
                    ],
                  ),
                  // Impact Dashboard sub-screen (Epic 6, Story 6.4).
                  GoRoute(
                    path: 'impact',
                    builder: (context, state) => const ImpactDashboardScreen(),
                  ),
                ],
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
