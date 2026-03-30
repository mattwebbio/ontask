import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/today/presentation/widgets/today_empty_state.dart';

void main() {
  group('TodayEmptyState', () {
    bool ctaTapped = false;

    Widget _buildWidget() {
      ctaTapped = false;
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: TodayEmptyState(
            onAddTapped: () {
              ctaTapped = true;
            },
          ),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.byType(TodayEmptyState), findsOneWidget);
    });

    testWidgets('displays nudge title: "Nothing scheduled."', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.text(AppStrings.todayEmptyTitle), findsOneWidget);
    });

    testWidgets('displays Add CTA: "Add something?"', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.text(AppStrings.todayEmptyAddCta), findsOneWidget);
    });

    testWidgets('tapping CTA calls onAddTapped callback', (tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.tap(find.text(AppStrings.todayEmptyAddCta));
      await tester.pump();

      expect(ctaTapped, isTrue);
    });

    testWidgets('copy is distinct from Now and Lists empty states',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      // Today uses "Nothing scheduled." — not "You're clear" or "No lists yet."
      expect(find.textContaining("You're clear"), findsNothing);
      expect(find.text("No lists yet."), findsNothing);
      expect(find.text(AppStrings.todayEmptyTitle), findsOneWidget);
    });
  });
}
