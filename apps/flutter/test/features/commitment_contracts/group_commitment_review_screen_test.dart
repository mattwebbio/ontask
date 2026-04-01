import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/group_commitment.dart';
import 'package:ontask/features/commitment_contracts/presentation/group_commitment_review_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for GroupCommitmentReviewScreen — Story 6.7 (FR29, FR30).
//
// Uses ProviderScope overrides — same pattern as stake_sheet_screen_test.dart.

class MockCommitmentContractsRepository extends Mock
    implements CommitmentContractsRepository {}

const _stubId = '00000000-0000-0000-0000-000000000001';
const _stubListId = '00000000-0000-0000-0000-000000000002';
const _stubTaskId = '00000000-0000-0000-0000-000000000003';
const _stubUserId = '00000000-0000-0000-0000-000000000099';

GroupCommitment _pendingCommitment({
  List<GroupCommitmentMember> members = const [],
}) {
  return GroupCommitment(
    id: _stubId,
    listId: _stubListId,
    taskId: _stubTaskId,
    proposedByUserId: _stubUserId,
    status: 'pending',
    members: members,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

GroupCommitment _activeCommitment({
  List<GroupCommitmentMember> members = const [],
}) {
  return GroupCommitment(
    id: _stubId,
    listId: _stubListId,
    taskId: _stubTaskId,
    proposedByUserId: _stubUserId,
    status: 'active',
    members: members,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

Future<void> pumpReviewScreen(
  WidgetTester tester, {
  required MockCommitmentContractsRepository mockRepo,
  required GroupCommitment commitment,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commitmentContractsRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: GroupCommitmentReviewScreen(commitment: commitment),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(
      GroupCommitment(
        id: _stubId,
        listId: _stubListId,
        taskId: _stubTaskId,
        proposedByUserId: _stubUserId,
        status: 'pending',
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
    );
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Member list rendering ─────────────────────────────────────────────────

  group('GroupCommitmentReviewScreen — member list', () {
    testWidgets(
      'shows pending approval status when commitment is pending',
      (tester) async {
        final mockRepo = MockCommitmentContractsRepository();
        final commitment = _pendingCommitment(members: [
          const GroupCommitmentMember(userId: _stubUserId),
        ]);

        await pumpReviewScreen(
          tester,
          mockRepo: mockRepo,
          commitment: commitment,
        );

        expect(
          find.text(AppStrings.groupCommitmentPendingStatus),
          findsWidgets,
        );
      },
    );
  });

  // ── Approve button ────────────────────────────────────────────────────────

  group('GroupCommitmentReviewScreen — approve button', () {
    testWidgets(
      '"Approve & set stake" button calls approveGroupCommitment',
      (tester) async {
        final mockRepo = MockCommitmentContractsRepository();
        final commitment = _pendingCommitment();
        final updatedCommitment = _pendingCommitment(members: [
          const GroupCommitmentMember(
            userId: _stubUserId,
            stakeAmountCents: 500,
            approved: true,
          ),
        ]);

        when(
          () => mockRepo.approveGroupCommitment(
            any(),
            stakeAmountCents: any(named: 'stakeAmountCents'),
          ),
        ).thenAnswer((_) async => updatedCommitment);

        when(
          () => mockRepo.getGroupCommitment(any()),
        ).thenAnswer((_) async => updatedCommitment);

        await pumpReviewScreen(
          tester,
          mockRepo: mockRepo,
          commitment: commitment,
        );

        await tester.tap(
          find.text(AppStrings.groupCommitmentApproveButton),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockRepo.approveGroupCommitment(
            _stubId,
            stakeAmountCents: any(named: 'stakeAmountCents'),
          ),
        ).called(1);
      },
    );
  });

  // ── Pool mode section visibility ──────────────────────────────────────────

  group('GroupCommitmentReviewScreen — pool mode section visibility', () {
    testWidgets(
      'pool mode section is hidden when commitment.status == pending',
      (tester) async {
        final mockRepo = MockCommitmentContractsRepository();
        final commitment = _pendingCommitment();

        await pumpReviewScreen(
          tester,
          mockRepo: mockRepo,
          commitment: commitment,
        );

        expect(find.text(AppStrings.poolModeSectionTitle), findsNothing);
      },
    );

    testWidgets(
      'pool mode section is shown when commitment.status == active',
      (tester) async {
        final mockRepo = MockCommitmentContractsRepository();
        final commitment = _activeCommitment();

        await pumpReviewScreen(
          tester,
          mockRepo: mockRepo,
          commitment: commitment,
        );

        expect(find.text(AppStrings.poolModeSectionTitle), findsOneWidget);
        expect(find.text(AppStrings.poolModeDescription), findsOneWidget);
        expect(find.text(AppStrings.poolModeToggleLabel), findsOneWidget);
      },
    );

    testWidgets(
      'toggling CupertinoSwitch calls setPoolModeOptIn with optIn: true',
      (tester) async {
        final mockRepo = MockCommitmentContractsRepository();
        final commitment = _activeCommitment();

        when(
          () => mockRepo.setPoolModeOptIn(
            any(),
            optIn: any(named: 'optIn'),
          ),
        ).thenAnswer((_) async {});

        await pumpReviewScreen(
          tester,
          mockRepo: mockRepo,
          commitment: commitment,
        );

        // Find and toggle the CupertinoSwitch
        final switchFinder = find.byType(CupertinoSwitch);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        verify(
          () => mockRepo.setPoolModeOptIn(
            _stubId,
            optIn: true,
          ),
        ).called(1);
      },
    );
  });
}
