import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/presentation/widgets/lists_empty_state.dart';

void main() {
  group('ListsEmptyState', () {
    Widget _buildWidget() {
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const Scaffold(
          body: ListsEmptyState(),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.byType(ListsEmptyState), findsOneWidget);
    });

    testWidgets('displays "No lists yet." title', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.text(AppStrings.listsEmptyTitle), findsOneWidget);
    });

    testWidgets('displays warm invitation subtitle', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.text(AppStrings.listsEmptySubtitle), findsOneWidget);
    });

    testWidgets('copy is distinct from Now and Today empty states',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      // Lists uses "No lists yet." — not "You're clear" or "Nothing scheduled."
      expect(find.textContaining("You're clear"), findsNothing);
      expect(find.text("Nothing scheduled."), findsNothing);
      expect(find.text(AppStrings.listsEmptyTitle), findsOneWidget);
    });

    testWidgets('subtitle copy invites organisation (not a generic placeholder)',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(
        find.text("Create a list to start organising what matters."),
        findsOneWidget,
      );
    });
  });
}
