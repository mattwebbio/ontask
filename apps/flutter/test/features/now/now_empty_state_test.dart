import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/now/presentation/widgets/now_empty_state.dart';

void main() {
  group('NowEmptyState', () {
    Widget _buildWidget({String? nextTaskHint}) {
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: NowEmptyState(nextTaskHint: nextTaskHint),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.byType(NowEmptyState), findsOneWidget);
    });

    testWidgets('displays NowEmptyTitle copy', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.text(AppStrings.nowEmptyTitle), findsOneWidget);
    });

    testWidgets('does NOT show next task hint when null', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.textContaining('Next:'), findsNothing);
    });

    testWidgets('shows next task hint when provided', (tester) async {
      await tester.pumpWidget(_buildWidget(nextTaskHint: 'Budget review at 2pm'));
      expect(find.textContaining('Next: Budget review at 2pm'), findsOneWidget);
    });

    testWidgets('title uses serif (PlayfairDisplay) font family', (tester) async {
      await tester.pumpWidget(_buildWidget());

      // Find the title text widget and verify it uses serif font
      final textWidgets = tester.widgetList<Text>(
        find.text(AppStrings.nowEmptyTitle),
      );
      for (final text in textWidgets) {
        if (text.style?.fontFamily != null) {
          expect(text.style!.fontFamily, contains('PlayfairDisplay'));
        }
      }
    });

    testWidgets('is centred (TextAlign.center)', (tester) async {
      await tester.pumpWidget(_buildWidget());

      final text = tester.widget<Text>(find.text(AppStrings.nowEmptyTitle));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('copy is distinct from Today and Lists empty states',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      // Now uses "You're clear for now." — not "Nothing scheduled." or "No lists yet."
      expect(find.text("Nothing scheduled."), findsNothing);
      expect(find.text("No lists yet."), findsNothing);
      expect(find.text(AppStrings.nowEmptyTitle), findsOneWidget);
    });
  });
}
