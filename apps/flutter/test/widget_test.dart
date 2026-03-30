// Widget smoke test for the OnTask app root.
//
// This test verifies that the app boots without errors and renders the
// navigation shell. Story 1.6 introduced the iOS shell; Story 1.7 added the
// macOS shell. The test is platform-aware since Platform.isMacOS is true when
// running tests locally on macOS.

import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/main.dart';

void main() {
  testWidgets('App boots and renders navigation shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OnTaskApp()));
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
}
