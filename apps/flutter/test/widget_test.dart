// Widget smoke test for the OnTask app root.
//
// This test verifies that the app boots without errors and renders via
// go_router. The full navigation shell is added in Story 1.6.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/main.dart';

void main() {
  testWidgets('App boots and renders placeholder screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OnTaskApp()));
    // Allow go_router to resolve the initial route.
    await tester.pumpAndSettle();

    // The placeholder route at '/' shows the text 'OnTask'.
    expect(find.text('OnTask'), findsWidgets);
  });
}
