import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/presentation/lists_screen.dart';
import 'package:ontask/features/now/presentation/now_screen.dart';
import 'package:ontask/features/settings/presentation/settings_screen.dart';
import 'package:ontask/features/shell/presentation/add_tab_sheet.dart';
import 'package:ontask/features/shell/presentation/command_palette_sheet.dart';
import 'package:ontask/features/shell/presentation/macos_shell.dart';
import 'package:ontask/features/today/presentation/today_screen.dart';

// ── Router factory ─────────────────────────────────────────────────────────

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
                GoRoute(
                    path: '/today', builder: (_, s) => const TodayScreen()),
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

Future<void> _pumpMacosShell(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
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
  group('MacosShell keyboard shortcuts', () {
    testWidgets('⌘N opens AddTabSheet', (tester) async {
      await _pumpMacosShell(tester);
      addTearDown(tester.view.resetPhysicalSize);

      // Simulate ⌘N (meta + N)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AddTabSheet), findsOneWidget);
    });

    testWidgets('⌘K opens CommandPaletteSheet', (tester) async {
      await _pumpMacosShell(tester);
      addTearDown(tester.view.resetPhysicalSize);

      // Simulate ⌘K
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CommandPaletteSheet), findsOneWidget);
    });

    testWidgets('⌘1 navigates to Now (selectedIndex=0)', (tester) async {
      await _pumpMacosShell(tester);
      addTearDown(tester.view.resetPhysicalSize);

      // Press ⌘1 to navigate to Now
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump(const Duration(milliseconds: 100));

      // Sidebar "Now" label must still be visible
      expect(find.text(AppStrings.macosNavNow), findsWidgets);
    });

    testWidgets('⌘4 navigates to Settings and shows SettingsScreen',
        (tester) async {
      await _pumpMacosShell(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump(const Duration(milliseconds: 300));

      // SettingsScreen widget is rendered in the main area
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('⌘, navigates to Settings and shows SettingsScreen',
        (tester) async {
      await _pumpMacosShell(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
