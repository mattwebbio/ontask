import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/presentation/lists_screen.dart';
import 'package:ontask/features/now/presentation/now_screen.dart';
import 'package:ontask/features/settings/presentation/settings_screen.dart';
import 'package:ontask/features/shell/presentation/add_tab_sheet.dart';
import 'package:ontask/features/shell/presentation/app_shell.dart';
import 'package:ontask/features/shell/presentation/macos_shell.dart';
import 'package:ontask/features/today/presentation/today_screen.dart';

// ── Router factory — creates a fresh router per test ─────────────────────────
// Mirrors app_router.dart including the settings branch added in Story 1.7.

GoRouter _makeRouter() => GoRouter(
      initialLocation: '/now',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/now',
                  builder: (_, __) => const NowScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/today',
                  builder: (_, __) => const TodayScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/add',
                  builder: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/lists',
                  builder: (_, __) => const ListsScreen(),
                ),
              ],
            ),
            // Settings branch — Story 1.7 (macOS sidebar item 3)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (_, __) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Pump widget and advance past all pending timers (including 800ms skeleton).
Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: _makeRouter(),
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      ),
    ),
  );
  // Advance past the 800ms skeleton delay in NowScreen / TodayScreen
  await tester.pump(const Duration(milliseconds: 900));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AppShell', () {
    if (Platform.isMacOS) {
      // On macOS the platform dispatch renders MacosShell instead of
      // CupertinoTabScaffold — verify that the macOS shell is active.
      testWidgets('renders MacosShell on macOS', (tester) async {
        await _pumpShell(tester);
        expect(find.byType(MacosShell), findsOneWidget);
      });

      testWidgets('macOS shell shows sidebar nav items: Now, Today, Lists, Settings',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await _pumpShell(tester);
        expect(find.text('Now'), findsWidgets);
        expect(find.text('Today'), findsWidgets);
        expect(find.text('Lists'), findsWidgets);
        expect(find.text('Settings'), findsOneWidget);
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });

      testWidgets('macOS shell shows New Task button in sidebar/toolbar',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await _pumpShell(tester);
        expect(find.text('New Task'), findsWidgets); // toolbar + sidebar
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });
    } else {
      // Non-macOS (Linux CI): verifies iOS CupertinoTabScaffold shell.
      testWidgets('renders four tab labels: Now, Today, Add, Lists',
          (tester) async {
        await _pumpShell(tester);

        expect(find.text('Now'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
        expect(find.text('Lists'), findsOneWidget);
      });

      testWidgets('contains CupertinoTabScaffold and CupertinoTabBar',
          (tester) async {
        await _pumpShell(tester);

        expect(find.byType(CupertinoTabScaffold), findsOneWidget);
        expect(find.byType(CupertinoTabBar), findsOneWidget);
      });

      testWidgets('tab bar has four items in order: Now, Today, Add, Lists',
          (tester) async {
        await _pumpShell(tester);

        final tabBar =
            tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
        expect(tabBar.items.length, 4);
        expect(tabBar.items[0].label, 'Now');
        expect(tabBar.items[1].label, 'Today');
        expect(tabBar.items[2].label, 'Add');
        expect(tabBar.items[3].label, 'Lists');
      });

      testWidgets('Add tab tap opens AddTabSheet modal', (tester) async {
        await _pumpShell(tester);

        // Tap the Add tab label in the tab bar
        await tester.tap(find.text('Add'));
        await tester.pump(); // start the modal animation
        await tester.pump(const Duration(milliseconds: 300)); // complete animation

        // AddTabSheet must be visible as a modal
        expect(find.byType(AddTabSheet), findsOneWidget);
      });

      testWidgets(
          'Add tab tap does NOT navigate: tab controller stays on previous tab',
          (tester) async {
        await _pumpShell(tester);

        await tester.tap(find.text('Add'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tab scaffold controller must not be at index 2 (Add)
        final scaffold = tester
            .widget<CupertinoTabScaffold>(find.byType(CupertinoTabScaffold));
        expect(scaffold.controller?.index ?? 0, isNot(2));
      });
    }
  });
}
