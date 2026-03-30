// Widget smoke test for the OnTask app root.
//
// This test verifies that the app boots without errors and renders the
// navigation shell. Story 1.6 introduced the iOS shell; Story 1.7 added the
// macOS shell. Story 1.8 added auth — the test overrides auth state to
// "authenticated" so the navigation shell is reachable.
// Story 1.9 added onboarding — the test must also mark onboarding as completed
// so the router does not redirect to /onboarding.
//
// The test is platform-aware since Platform.isMacOS is true when
// running tests locally on macOS.

import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    // Default: onboarding NOT completed — individual tests override as needed.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots and renders navigation shell', (tester) async {
    // Mark onboarding completed so the router does not redirect to /onboarding.
    SharedPreferences.setMockInitialValues({kOnboardingCompleted: true});
    final prefs = await SharedPreferences.getInstance();
    AuthStateNotifier.prewarmPrefs(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth state to authenticated so the router renders
          // the main navigation shell instead of the auth screen.
          authStateProvider.overrideWithValue(
            const AuthResult.authenticated(userId: 'test-user', provider: 'email'),
          ),
        ],
        child: const OnTaskApp(),
      ),
    );
    // Allow go_router to resolve the initial route, then advance past the
    // 800ms skeleton delay in NowScreen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    if (Platform.isMacOS) {
      // macOS: sidebar-based navigation shell; no bottom tab bar.
      // Sidebar nav items and toolbar both show section labels.
      expect(find.text('Now'), findsWidgets);
      expect(find.text('New Task'), findsWidgets);
    } else {
      // iOS / Linux CI: four-tab CupertinoTabScaffold shell.
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Lists'), findsOneWidget);

      // CupertinoTabBar is present
      expect(find.byType(CupertinoTabBar), findsOneWidget);
    }
  });

  testWidgets('App shows auth screen when unauthenticated', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(const AuthResult.unauthenticated()),
        ],
        child: const OnTaskApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The auth gate redirects to /auth/sign-in; verify auth UI is shown.
    expect(find.text('On Task'), findsOneWidget);
  });
}
