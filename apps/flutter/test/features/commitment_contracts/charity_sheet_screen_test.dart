import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/charity_selection.dart';
import 'package:ontask/features/commitment_contracts/domain/nonprofit.dart';
import 'package:ontask/features/commitment_contracts/presentation/charity_sheet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for CharitySheetScreen — Story 6.3 (FR26, AC1–3).
//
// Uses ProviderScope overrides — same ProviderContainer pattern as
// Stories 5.4/5.6/6.1/6.2.

class MockCommitmentContractsRepository extends Mock
    implements CommitmentContractsRepository {}

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

/// Pumps [CharitySheetScreen] with an overridden [commitmentContractsRepositoryProvider].
Future<void> pumpCharitySheetScreen(
  WidgetTester tester, {
  required MockCommitmentContractsRepository mockRepo,
  String? currentCharityId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commitmentContractsRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: CharitySheetScreen(currentCharityId: currentCharityId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(
      const Nonprofit(id: 'stub', name: 'Stub'),
    );
    registerFallbackValue(
      const CharitySelection(),
    );
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Confirm button disabled before selection ───────────────────────────────

  group('CharitySheetScreen — Confirm button', () {
    testWidgets('Confirm button onPressed is null before any nonprofit is selected',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.searchCharities(
            query: any(named: 'query'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _stubNonprofits);

      await pumpCharitySheetScreen(tester, mockRepo: mockRepo);

      // Find the CupertinoButton with charityConfirmButton text.
      final buttons = tester.widgetList<CupertinoButton>(
        find.byType(CupertinoButton),
      );
      final confirmButton = buttons.firstWhere(
        (b) {
          final child = b.child;
          return child is Text && child.data == AppStrings.charityConfirmButton;
        },
        orElse: () => throw StateError('Confirm button not found'),
      );

      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('Confirm button is enabled after selecting a nonprofit',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.searchCharities(
            query: any(named: 'query'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _stubNonprofits);

      await pumpCharitySheetScreen(tester, mockRepo: mockRepo);

      // Tap the first nonprofit row to select it.
      await tester.tap(find.text('American Red Cross'));
      await tester.pumpAndSettle();

      // Find confirm button — it should now be enabled.
      final buttons = tester.widgetList<CupertinoButton>(
        find.byType(CupertinoButton),
      );
      final confirmButton = buttons.firstWhere(
        (b) {
          final child = b.child;
          return child is Text && child.data == AppStrings.charityConfirmButton;
        },
        orElse: () => throw StateError('Confirm button not found'),
      );

      expect(confirmButton.onPressed, isNotNull);
    });
  });

  // ── Selection updates checkmark ────────────────────────────────────────────

  group('CharitySheetScreen — checkmark on selection', () {
    testWidgets('selecting a nonprofit shows checkmark in the list', (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.searchCharities(
            query: any(named: 'query'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _stubNonprofits);

      await pumpCharitySheetScreen(tester, mockRepo: mockRepo);

      // No checkmark before selection.
      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsNothing);

      // Tap a nonprofit to select.
      await tester.tap(find.text('American Red Cross'));
      await tester.pumpAndSettle();

      // Checkmark should now appear.
      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
    });
  });
}
