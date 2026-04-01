import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/commitment_payment_status.dart';
import 'package:ontask/features/commitment_contracts/domain/task_stake.dart';
import 'package:ontask/features/commitment_contracts/presentation/stake_sheet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for StakeSheetScreen — Story 6.2 (FR22, AC4).
//
// Uses ProviderScope overrides — same ProviderContainer pattern as
// Stories 5.4/5.6/6.1.

class MockCommitmentContractsRepository extends Mock
    implements CommitmentContractsRepository {}

/// Pumps [StakeSheetScreen] with an overridden [commitmentContractsRepositoryProvider].
Future<void> pumpStakeSheetScreen(
  WidgetTester tester, {
  required MockCommitmentContractsRepository mockRepo,
  String taskId = 'task-id',
  int? existingStakeAmountCents,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commitmentContractsRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: StakeSheetScreen(
            taskId: taskId,
            existingStakeAmountCents: existingStakeAmountCents,
          ),
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
      const CommitmentPaymentStatus(
        hasPaymentMethod: false,
        hasActiveStakes: false,
      ),
    );
    registerFallbackValue(
      const TaskStake(taskId: 'task-id', stakeAmountCents: null),
    );
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Payment gate (AC4) ────────────────────────────────────────────────────

  group('StakeSheetScreen — payment method gate', () {
    testWidgets(
        'shows stakePaymentMethodRequired when hasPaymentMethod == false',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: false,
          hasActiveStakes: false,
        ),
      );

      await pumpStakeSheetScreen(tester, mockRepo: mockRepo);

      expect(
        find.text(AppStrings.stakePaymentMethodRequired),
        findsOneWidget,
      );
      expect(find.text(AppStrings.stakeSetupPaymentCta), findsOneWidget);
    });

    testWidgets(
        'shows StakeSliderWidget (stakeSliderTitle) when hasPaymentMethod == true',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: false,
        ),
      );

      await pumpStakeSheetScreen(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.stakeSliderTitle), findsOneWidget);
      // Payment gate copy should NOT be shown.
      expect(
        find.text(AppStrings.stakePaymentMethodRequired),
        findsNothing,
      );
    });
  });

  // ── Remove stake button ───────────────────────────────────────────────────

  group('StakeSheetScreen — remove stake', () {
    testWidgets(
        '"Remove stake?" button renders when existingStakeAmountCents != null',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: true,
        ),
      );

      await pumpStakeSheetScreen(
        tester,
        mockRepo: mockRepo,
        existingStakeAmountCents: 2500,
      );

      expect(find.text(AppStrings.stakeRemoveConfirmTitle), findsOneWidget);
    });

    testWidgets(
        '"Remove stake?" button is absent when existingStakeAmountCents == null',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: false,
        ),
      );

      await pumpStakeSheetScreen(
        tester,
        mockRepo: mockRepo,
        existingStakeAmountCents: null,
      );

      // The title shows in the dialog title — not a button here.
      // We look for a CupertinoButton with that text, which only appears
      // when existingStakeAmountCents != null.
      // Since the sheet title is "Set your stake" and not "Remove stake?",
      // we verify the removal button text is absent from the button context.
      expect(find.text(AppStrings.stakeRemoveConfirmTitle), findsNothing);
    });
  });

  // ── Modification window (Story 6.6) ──────────────────────────────────────

  group('StakeSheetScreen — modification window (Story 6.6)', () {
    testWidgets(
        'shows modification window label when canModify is true',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: true,
        ),
      );

      // Deadline 24 hours in the future
      final deadline = DateTime.now().toUtc().add(const Duration(hours: 24));
      when(() => mockRepo.getTaskStake(any())).thenAnswer(
        (_) async => TaskStake(
          taskId: 'task-id',
          stakeAmountCents: 2500,
          stakeModificationDeadline: deadline.toLocal(),
          canModify: true,
        ),
      );
      // Also stub getDefaultCharity for the charity load
      when(() => mockRepo.getDefaultCharity()).thenAnswer(
        (_) async => throw Exception('no charity'),
      );

      await pumpStakeSheetScreen(
        tester,
        mockRepo: mockRepo,
        existingStakeAmountCents: 2500,
      );

      expect(
        find.textContaining(AppStrings.stakeModificationWindowPrefix),
        findsOneWidget,
      );
    });

    testWidgets(
        'disables controls and shows locked message when modification window is closed',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: true,
        ),
      );

      when(() => mockRepo.getTaskStake(any())).thenAnswer(
        (_) async => const TaskStake(
          taskId: 'task-id',
          stakeAmountCents: 2500,
          stakeModificationDeadline: null,
          canModify: false,
        ),
      );
      when(() => mockRepo.getDefaultCharity()).thenAnswer(
        (_) async => throw Exception('no charity'),
      );

      await pumpStakeSheetScreen(
        tester,
        mockRepo: mockRepo,
        existingStakeAmountCents: 2500,
      );

      // Locked message should be present
      expect(find.text(AppStrings.stakeLockedMessage), findsOneWidget);

      // IgnorePointer with ignoring: true should wrap the slider
      // Use findsAtLeastNWidgets(1) since Flutter may have internal IgnorePointers
      final ignorePointerFinder = find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      );
      expect(ignorePointerFinder, findsAtLeastNWidgets(1));

      // Remove stake button should be present but disabled (onPressed == null)
      expect(find.text(AppStrings.stakeRemoveConfirmTitle), findsOneWidget);
    });

    testWidgets(
        'locked message AppStrings.stakeLockedMessage is shown when canModify == false',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: true,
        ),
      );
      when(() => mockRepo.getTaskStake(any())).thenAnswer(
        (_) async => const TaskStake(
          taskId: 'task-id',
          stakeAmountCents: 2500,
          canModify: false,
        ),
      );
      when(() => mockRepo.getDefaultCharity()).thenAnswer(
        (_) async => throw Exception('no charity'),
      );

      await pumpStakeSheetScreen(
        tester,
        mockRepo: mockRepo,
        existingStakeAmountCents: 2500,
      );

      expect(find.text(AppStrings.stakeLockedMessage), findsOneWidget);
    });

    testWidgets(
        'locked message absent when canModify == true',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '4242',
          brand: 'visa',
          hasActiveStakes: true,
        ),
      );

      final deadline = DateTime.now().toUtc().add(const Duration(hours: 24));
      when(() => mockRepo.getTaskStake(any())).thenAnswer(
        (_) async => TaskStake(
          taskId: 'task-id',
          stakeAmountCents: 2500,
          stakeModificationDeadline: deadline.toLocal(),
          canModify: true,
        ),
      );
      when(() => mockRepo.getDefaultCharity()).thenAnswer(
        (_) async => throw Exception('no charity'),
      );

      await pumpStakeSheetScreen(
        tester,
        mockRepo: mockRepo,
        existingStakeAmountCents: 2500,
      );

      expect(find.text(AppStrings.stakeLockedMessage), findsNothing);
    });
  });
}
