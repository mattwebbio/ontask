import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/presentation/lists_screen.dart';
import 'package:ontask/features/now/presentation/now_screen.dart';
import 'package:ontask/features/settings/presentation/settings_screen.dart';
import 'package:ontask/features/shell/presentation/add_tab_sheet.dart';
import 'package:ontask/features/shell/presentation/macos_shell.dart';
import 'package:ontask/features/today/presentation/today_screen.dart';

// ── Router factory ──────────────────────────────────────────────────────────

GoRouter _makeRouter() => GoRouter(
      initialLocation: '/now',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MacosShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/now', builder: (_, s) => const NowScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/today', builder: (_, s) => const TodayScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                    path: '/add', builder: (_, s) => const SizedBox.shrink()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                    path: '/lists', builder: (_, s) => const ListsScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                    path: '/settings',
                    builder: (_, s) => const SettingsScreen()),
              ],
            ),
          ],
        ),
      ],
    );

Future<void> _pumpMacosShell(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
}) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: _makeRouter(),
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('MacosShell layout', () {
    testWidgets(
        'three-pane layout at 1200pt: sidebar, detail panel, and main area visible',
        (tester) async {
      await _pumpMacosShell(tester, size: const Size(1200, 800));
      addTearDown(tester.view.resetPhysicalSize);

      expect(find.byType(MacosShell), findsOneWidget);

      // Sidebar "New Task" button present
      expect(find.text(AppStrings.macosNewTask), findsWidgets);

      // Detail panel placeholder text present in three-pane mode
      expect(
        find.text('Detail panel — coming in future story.'),
        findsOneWidget,
      );
    });

    testWidgets('two-pane layout at 1000pt: detail panel hidden',
        (tester) async {
      await _pumpMacosShell(tester, size: const Size(1000, 700));
      addTearDown(tester.view.resetPhysicalSize);

      expect(find.byType(MacosShell), findsOneWidget);

      // Detail panel text must NOT be visible (Offstage)
      expect(
        find.text('Detail panel — coming in future story.'),
        findsNothing,
      );
    });

    testWidgets(
        'sidebar contains four navigation items: Now, Today, Lists, Settings',
        (tester) async {
      await _pumpMacosShell(tester, size: const Size(1200, 800));
      addTearDown(tester.view.resetPhysicalSize);

      expect(find.text(AppStrings.macosNavNow), findsWidgets);
      expect(find.text(AppStrings.macosNavToday), findsWidgets);
      expect(find.text(AppStrings.macosNavLists), findsWidgets);
      expect(find.text(AppStrings.macosNavSettings), findsOneWidget);
    });

    testWidgets('New Task button is present in sidebar and toolbar',
        (tester) async {
      await _pumpMacosShell(tester, size: const Size(1200, 800));
      addTearDown(tester.view.resetPhysicalSize);

      // Both toolbar and sidebar have "New Task" buttons
      expect(find.text(AppStrings.macosNewTask), findsWidgets);
    });

    testWidgets('no bottom tab bar is rendered on macOS shell', (tester) async {
      await _pumpMacosShell(tester, size: const Size(1200, 800));
      addTearDown(tester.view.resetPhysicalSize);

      // No BottomNavigationBar in the macOS shell
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('New Task button in sidebar opens AddTabSheet', (tester) async {
      await _pumpMacosShell(tester, size: const Size(1200, 800));
      addTearDown(tester.view.resetPhysicalSize);

      // Find the first "New Task" button (sidebar)
      final newTaskButtons = find.text(AppStrings.macosNewTask);
      expect(newTaskButtons, findsWidgets);

      // Tap the first New Task button
      await tester.tap(newTaskButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AddTabSheet), findsOneWidget);
    });
  });
}
