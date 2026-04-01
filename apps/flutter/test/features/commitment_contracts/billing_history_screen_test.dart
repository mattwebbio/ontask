import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/billing_entry.dart';
import 'package:ontask/features/commitment_contracts/presentation/billing_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for BillingHistoryScreen — Story 6.9 (FR65, AC: 1).
//
// Uses ProviderScope overrides — established pattern from Stories 6.7, 6.8.
// Wraps in MaterialApp with AppTheme.light() per project convention.

class MockCommitmentContractsRepository extends Mock
    implements CommitmentContractsRepository {}

/// Pumps [BillingHistoryScreen] with an overridden [commitmentContractsRepositoryProvider].
Future<void> pumpBillingHistoryScreen(
  WidgetTester tester, {
  required MockCommitmentContractsRepository mockRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commitmentContractsRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const BillingHistoryScreen(),
      ),
    ),
  );
}

final _chargedEntry = BillingEntry(
  id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  taskName: 'Complete quarterly report',
  date: DateTime(2026, 3, 15, 10, 0),
  amountCents: 5000,
  disbursementStatus: 'completed',
  charityName: 'American Red Cross',
);

final _pendingEntry = BillingEntry(
  id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  taskName: 'Finish side project milestone',
  date: DateTime(2026, 3, 20, 14, 30),
  amountCents: 2500,
  disbursementStatus: 'pending',
  charityName: 'Doctors Without Borders',
);

final _cancelledEntry = BillingEntry(
  id: 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  taskName: 'Read three chapters',
  date: DateTime(2026, 3, 25, 9, 0),
  amountCents: null,
  disbursementStatus: 'cancelled',
  charityName: null,
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Loading state ─────────────────────────────────────────────────────────

  testWidgets('shows CupertinoActivityIndicator while loading', (tester) async {
    final mockRepo = MockCommitmentContractsRepository();
    final completer = Completer<List<BillingEntry>>();
    when(() => mockRepo.getBillingHistory()).thenAnswer((_) => completer.future);

    await pumpBillingHistoryScreen(tester, mockRepo: mockRepo);
    await tester.pump();

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    completer.complete([]);
  });

  // ── Charged entry ─────────────────────────────────────────────────────────

  testWidgets(
    'renders charged entry with formatted amount and Donated badge',
    (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getBillingHistory())
          .thenAnswer((_) async => [_chargedEntry]);

      await pumpBillingHistoryScreen(tester, mockRepo: mockRepo);
      await tester.pumpAndSettle();

      expect(find.text('Complete quarterly report'), findsOneWidget);
      expect(find.text(r'$50'), findsOneWidget);
      expect(find.text(AppStrings.billingStatusDonated), findsOneWidget);
      expect(find.text('American Red Cross'), findsOneWidget);
    },
  );

  // ── Cancelled entry ───────────────────────────────────────────────────────

  testWidgets(
    'renders cancelled entry showing billingCancelledNoCharge and no amount',
    (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getBillingHistory())
          .thenAnswer((_) async => [_cancelledEntry]);

      await pumpBillingHistoryScreen(tester, mockRepo: mockRepo);
      await tester.pumpAndSettle();

      expect(find.text('Read three chapters'), findsOneWidget);
      expect(find.text(AppStrings.billingCancelledNoCharge), findsOneWidget);
      expect(find.text(AppStrings.billingStatusCancelled), findsOneWidget);
      // No amount shown for cancelled entries
      expect(find.text(r'$0'), findsNothing);
    },
  );

  // ── Pending entry ─────────────────────────────────────────────────────────

  testWidgets('renders pending entry with Pending badge', (tester) async {
    final mockRepo = MockCommitmentContractsRepository();
    when(() => mockRepo.getBillingHistory())
        .thenAnswer((_) async => [_pendingEntry]);

    await pumpBillingHistoryScreen(tester, mockRepo: mockRepo);
    await tester.pumpAndSettle();

    expect(find.text('Finish side project milestone'), findsOneWidget);
    expect(find.text(AppStrings.billingStatusPending), findsOneWidget);
    expect(find.text(r'$25'), findsOneWidget);
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  testWidgets('shows empty state text when entries list is empty',
      (tester) async {
    final mockRepo = MockCommitmentContractsRepository();
    when(() => mockRepo.getBillingHistory()).thenAnswer((_) async => []);

    await pumpBillingHistoryScreen(tester, mockRepo: mockRepo);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingHistoryEmpty), findsOneWidget);
  });

  // ── Error state ───────────────────────────────────────────────────────────

  testWidgets('shows error text when getBillingHistory throws', (tester) async {
    final mockRepo = MockCommitmentContractsRepository();
    when(() => mockRepo.getBillingHistory())
        .thenThrow(Exception('Network error'));

    await pumpBillingHistoryScreen(tester, mockRepo: mockRepo);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.billingHistoryLoadError), findsOneWidget);
  });
}
