import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/domain/nonprofit.dart';
import 'package:ontask/features/commitment_contracts/presentation/widgets/charity_search_delegate.dart';

// Widget tests for CharitySearchDelegate — Story 6.3 (FR26, AC1).
//
// Wraps in MaterialApp with OnTaskTheme to resolve OnTaskColors extension.

const _stubNonprofits = [
  Nonprofit(
    id: 'american-red-cross',
    name: 'American Red Cross',
    description: 'Emergency response and disaster relief.',
    categories: ['Health'],
  ),
  Nonprofit(
    id: 'unicef',
    name: 'UNICEF',
    description: "Children's rights and emergency relief worldwide.",
    categories: ['Human Rights'],
  ),
];

Future<void> pumpCharitySearchDelegate(
  WidgetTester tester, {
  List<Nonprofit> nonprofits = _stubNonprofits,
  bool isLoading = false,
  String? selectedCharityId,
  void Function(String)? onSearchChanged,
  void Function(String?)? onCategoryChanged,
  void Function(Nonprofit)? onSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: CharitySearchDelegate(
          nonprofits: nonprofits,
          isLoading: isLoading,
          selectedCharityId: selectedCharityId,
          onSearchChanged: onSearchChanged ?? (q) {},
          onCategoryChanged: onCategoryChanged ?? (c) {},
          onSelected: onSelected ?? (n) {},
        ),
      ),
    ),
  );
  // Use pump(duration) instead of pumpAndSettle when isLoading=true to
  // avoid CupertinoActivityIndicator animation causing pumpAndSettle timeout.
  if (isLoading && nonprofits.isEmpty) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  // ── Nonprofit list rows ────────────────────────────────────────────────────

  group('CharitySearchDelegate — nonprofit list', () {
    testWidgets('renders nonprofit name rows', (tester) async {
      await pumpCharitySearchDelegate(tester);

      expect(find.text('American Red Cross'), findsOneWidget);
      expect(find.text('UNICEF'), findsOneWidget);
    });

    testWidgets('renders nonprofit description snippets', (tester) async {
      await pumpCharitySearchDelegate(tester);

      expect(
        find.text('Emergency response and disaster relief.'),
        findsOneWidget,
      );
    });
  });

  // ── Selected state ────────────────────────────────────────────────────────

  group('CharitySearchDelegate — selected state', () {
    testWidgets('shows checkmark icon for selected nonprofit', (tester) async {
      await pumpCharitySearchDelegate(
        tester,
        selectedCharityId: 'american-red-cross',
      );

      // CupertinoIcons.checkmark_circle_fill should be present for the selected row.
      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
    });

    testWidgets('no checkmark shown when no nonprofit is selected', (tester) async {
      await pumpCharitySearchDelegate(tester, selectedCharityId: null);

      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsNothing);
    });
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  group('CharitySearchDelegate — empty state', () {
    testWidgets('shows charitySearchEmpty message when nonprofits is empty and not loading',
        (tester) async {
      await pumpCharitySearchDelegate(tester, nonprofits: [], isLoading: false);

      expect(find.text(AppStrings.charitySearchEmpty), findsOneWidget);
    });

    testWidgets('does NOT show charitySearchEmpty when nonprofits are present',
        (tester) async {
      await pumpCharitySearchDelegate(tester);

      expect(find.text(AppStrings.charitySearchEmpty), findsNothing);
    });
  });

  // ── Loading state ─────────────────────────────────────────────────────────

  group('CharitySearchDelegate — loading state', () {
    testWidgets(
        'shows CupertinoActivityIndicator when isLoading=true and nonprofits empty',
        (tester) async {
      await pumpCharitySearchDelegate(
        tester,
        nonprofits: [],
        isLoading: true,
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets(
        'does NOT show CupertinoActivityIndicator when nonprofits are present',
        (tester) async {
      await pumpCharitySearchDelegate(tester, isLoading: true);

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });
  });
}
