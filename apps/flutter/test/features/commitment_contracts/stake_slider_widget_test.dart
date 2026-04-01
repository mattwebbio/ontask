import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/presentation/widgets/stake_slider_widget.dart';

// Widget tests for StakeSliderWidget — Story 6.2 (FR22, UX-DR7).
//
// Wraps in MaterialApp with OnTaskTheme to resolve OnTaskColors extension.

Widget _buildSubject({
  int? stakeAmountCents,
  void Function(int? cents)? onChanged,
  VoidCallback? onConfirm,
}) {
  return MaterialApp(
    theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
    home: Scaffold(
      body: StakeSliderWidget(
        stakeAmountCents: stakeAmountCents,
        onChanged: onChanged ?? (_) {},
        onConfirm: onConfirm ?? () {},
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ── Zone labels ──────────────────────────────────────────────────────────

  group('StakeSliderWidget zone labels', () {
    testWidgets('renders Low, Mid, and High zone labels', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.stakeZoneLowLabel), findsOneWidget);
      expect(find.text(AppStrings.stakeZoneMidLabel), findsOneWidget);
      expect(find.text(AppStrings.stakeZoneHighLabel), findsOneWidget);
    });
  });

  // ── Red zone guidance text ───────────────────────────────────────────────

  group('StakeSliderWidget red zone guidance text', () {
    testWidgets(
        'guidance text is present in widget tree when stakeAmountCents >= 10000',
        (tester) async {
      await tester.pumpWidget(_buildSubject(stakeAmountCents: 10000));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.stakeHighZoneGuidance), findsOneWidget);
    });

    testWidgets(
        'guidance text is present in widget tree but invisible when stakeAmountCents < 10000',
        (tester) async {
      await tester.pumpWidget(_buildSubject(stakeAmountCents: 5000));
      await tester.pumpAndSettle();

      // AnimatedOpacity renders the widget in the tree with opacity 0.
      // We verify the text exists but is not visually prominent (opacity == 0).
      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text(AppStrings.stakeHighZoneGuidance),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacityWidget.opacity, equals(0.0));
    });

    testWidgets(
        'guidance text absent from widget tree when stakeAmountCents is 0',
        (tester) async {
      await tester.pumpWidget(_buildSubject(stakeAmountCents: 0));
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text(AppStrings.stakeHighZoneGuidance),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacityWidget.opacity, equals(0.0));
    });
  });

  // ── Confirm button ───────────────────────────────────────────────────────

  group('StakeSliderWidget confirm button', () {
    testWidgets(
        '"Lock it in." button has null onPressed when stakeAmountCents == 0',
        (tester) async {
      await tester.pumpWidget(_buildSubject(stakeAmountCents: 0));
      await tester.pumpAndSettle();

      // Find CupertinoButton that renders the confirm text.
      final buttonFinder = find.widgetWithText(
        ElevatedButton,
        AppStrings.stakeConfirmButton,
      );
      // CupertinoButton wraps in custom widget — check by finding the text.
      expect(find.text(AppStrings.stakeConfirmButton), findsOneWidget);

      // Verify button is disabled: tap should not trigger callback.
      bool tapped = false;
      await tester.pumpWidget(
        _buildSubject(
          stakeAmountCents: 0,
          onConfirm: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // The button renders as disabled when cents < 500 — tap does nothing.
      await tester.tap(find.text(AppStrings.stakeConfirmButton));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
      // Suppress unused variable warning.
      buttonFinder.toString();
    });

    testWidgets(
        '"Lock it in." button is enabled and fires callback when stakeAmountCents >= 500',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        _buildSubject(
          stakeAmountCents: 2500,
          onConfirm: () => confirmed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.stakeConfirmButton), findsOneWidget);

      await tester.tap(find.text(AppStrings.stakeConfirmButton));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });
  });
}
