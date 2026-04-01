import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/impact_milestone.dart';
import 'package:ontask/features/commitment_contracts/domain/impact_summary.dart';
import 'package:ontask/features/commitment_contracts/presentation/impact_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for ImpactDashboardScreen — Story 6.4 (FR27, AC1, AC2).
//
// Uses ProviderScope overrides — same ProviderContainer pattern as
// Stories 5.4/5.6/6.1/6.2/6.3.

class MockCommitmentContractsRepository extends Mock
    implements CommitmentContractsRepository {}

final _stubMilestones = [
  ImpactMilestone(
    id: 'first-kept',
    title: 'First commitment kept.',
    body: 'You showed up when it mattered.',
    earnedAt: DateTime.utc(2026, 1, 15),
    shareText: 'I kept my first commitment with On Task.',
  ),
  ImpactMilestone(
    id: 'first-donation',
    title: 'First donation made.',
    body: 'Even a missed commitment moved something good into the world.',
    earnedAt: DateTime.utc(2026, 2, 1),
    shareText: 'I donated \$25 to the American Red Cross through On Task.',
  ),
];

final _stubSummary = ImpactSummary(
  totalDonatedCents: 2500,
  commitmentsKept: 3,
  commitmentsMissed: 1,
  charityBreakdown: const [],
  milestones: _stubMilestones,
);

final _emptySummary = const ImpactSummary(
  totalDonatedCents: 0,
  commitmentsKept: 0,
  commitmentsMissed: 0,
);

/// Pumps [ImpactDashboardScreen] with an overridden [commitmentContractsRepositoryProvider].
Future<void> pumpImpactDashboardScreen(
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
        home: const ImpactDashboardScreen(),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Loading state ─────────────────────────────────────────────────────────

  group('ImpactDashboardScreen — loading state', () {
    testWidgets(
        'CupertinoActivityIndicator shown on initial load before data arrives',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      // Use a Completer that never resolves to hold the loading state indefinitely.
      // Never completes in this test — keeps screen in loading state.
      final completer = Completer<ImpactSummary>();
      when(() => mockRepo.getImpactSummary())
          .thenAnswer((_) => completer.future);

      await pumpImpactDashboardScreen(tester, mockRepo: mockRepo);
      // Use pump() (NOT pumpAndSettle()) — CupertinoActivityIndicator animation
      // keeps ticking and causes pumpAndSettle() to timeout.
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      // Resolve the completer to clean up pending async work before test ends.
      completer.complete(_stubSummary);
      await tester.pumpAndSettle();
    });
  });

  // ── Loaded state ──────────────────────────────────────────────────────────

  group('ImpactDashboardScreen — loaded state', () {
    testWidgets('primary stat cells rendered with correct values after data loads',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getImpactSummary())
          .thenAnswer((_) async => _stubSummary);

      await pumpImpactDashboardScreen(tester, mockRepo: mockRepo);
      await tester.pumpAndSettle();

      // commitmentsKept = 3
      expect(find.text('3'), findsOneWidget);
      // totalDonatedCents = 2500 → '$25'
      expect(find.text('\$25'), findsOneWidget);
    });

    testWidgets('milestone cells rendered for each milestone in summary',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getImpactSummary())
          .thenAnswer((_) async => _stubSummary);

      await pumpImpactDashboardScreen(tester, mockRepo: mockRepo);
      await tester.pumpAndSettle();

      expect(find.text('First commitment kept.'), findsOneWidget);
      expect(find.text('First donation made.'), findsOneWidget);
    });
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  group('ImpactDashboardScreen — empty state', () {
    testWidgets('empty state message shown when milestones list is empty',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getImpactSummary())
          .thenAnswer((_) async => _emptySummary);

      await pumpImpactDashboardScreen(tester, mockRepo: mockRepo);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your story is just beginning. Complete your first staked commitment to see your impact here.',
        ),
        findsOneWidget,
      );
    });
  });
}
