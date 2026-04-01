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
}
