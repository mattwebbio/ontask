// Widget smoke test for the OnTask app root.
//
// This test verifies that the app boots without errors and renders the
// navigation shell introduced in Story 1.6.

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

    // The Story 1.6 shell renders four tabs: Now, Today, Add, Lists.
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);

    // CupertinoTabBar is present
    expect(find.byType(CupertinoTabBar), findsOneWidget);
  });
}
