import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/disputes/presentation/dispute_confirmation_view.dart';

// Widget tests for DisputeConfirmationView — Story 7.8 (FR39-40, UX-DR33).
//
// Verifies that all three trust-critical message points are rendered simultaneously,
// the heading is correct, tapping Done calls onDone, and accessibility liveRegion
// is set on the heading.

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<void> pumpView(
  WidgetTester tester, {
  VoidCallback? onDone,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DisputeConfirmationView(
              onDone: onDone ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DisputeConfirmationView — heading (UX-DR33)', () {
    testWidgets('renders disputeConfirmationTitle "Review requested"',
        (tester) async {
      await pumpView(tester);

      expect(
        find.text(AppStrings.disputeConfirmationTitle),
        findsOneWidget,
      );
      expect(AppStrings.disputeConfirmationTitle, 'Review requested');
    });
  });

  group('DisputeConfirmationView — trust-critical points (UX-DR33)', () {
    testWidgets('renders all three trust-critical message strings simultaneously',
        (tester) async {
      await pumpView(tester);

      // All three must be present at the same time — UX-DR33 requires simultaneous display.
      expect(
        find.text(AppStrings.disputeConfirmationPoint1),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.disputeConfirmationPoint2),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.disputeConfirmationPoint3),
        findsOneWidget,
      );
    });

    testWidgets('point1 text is correct', (tester) async {
      expect(
        AppStrings.disputeConfirmationPoint1,
        'Your dispute was received and is being reviewed',
      );
    });

    testWidgets('point2 text is correct', (tester) async {
      expect(
        AppStrings.disputeConfirmationPoint2,
        'Your stake will not be charged during review',
      );
    });

    testWidgets('point3 text is correct', (tester) async {
      expect(
        AppStrings.disputeConfirmationPoint3,
        'You\u2019ll have a response within 24 hours',
      );
    });
  });

  group('DisputeConfirmationView — Done CTA', () {
    testWidgets('tapping "Done" calls onDone callback', (tester) async {
      var callCount = 0;

      await pumpView(tester, onDone: () => callCount++);

      final doneFinder = find.text(AppStrings.disputeConfirmationDoneCta);
      expect(doneFinder, findsOneWidget);

      await tester.tap(doneFinder);
      await tester.pump();

      expect(callCount, 1);
    });
  });

  group('DisputeConfirmationView — accessibility', () {
    testWidgets(
        'heading has Semantics liveRegion: true for accessibility announcement',
        (tester) async {
      await pumpView(tester);

      // The heading widget must be wrapped in Semantics with liveRegion: true.
      final liveRegionFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      expect(liveRegionFinder, findsAtLeast(1));
    });
  });
}
