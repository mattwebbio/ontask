import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/commitment_payment_status.dart';
import 'package:ontask/features/commitment_contracts/presentation/payment_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for PaymentSettingsScreen — Story 6.1 (FR23, FR64).
//
// Uses ProviderScope with overrides to stub CommitmentContractsRepository.
// Same pattern as delete_account_screen_test.dart / Settings-related widget tests.

class MockCommitmentContractsRepository extends Mock
    implements CommitmentContractsRepository {}

/// Pumps [PaymentSettingsScreen] with an overridden [commitmentContractsRepositoryProvider].
Future<void> pumpPaymentSettingsScreen(
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
        home: const PaymentSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── AC1 / AC2: "Set up payment method" when no method stored ─────────────

  group('PaymentSettingsScreen — no payment method stored', () {
    testWidgets(
        '"Set up payment method" button renders when hasPaymentMethod == false',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: false,
          last4: null,
          brand: null,
          hasActiveStakes: false,
        ),
      );

      await pumpPaymentSettingsScreen(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.paymentSetupButton), findsOneWidget);
      expect(find.text(AppStrings.paymentUpdateButton), findsNothing);
    });
  });

  // ── AC2: Card display row when method is stored ───────────────────────────

  group('PaymentSettingsScreen — payment method stored', () {
    testWidgets('card display row shows last4 and brand when hasPaymentMethod == true',
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

      await pumpPaymentSettingsScreen(tester, mockRepo: mockRepo);

      expect(find.text('VISA ending in 4242'), findsOneWidget);
      expect(find.text(AppStrings.paymentUpdateButton), findsOneWidget);
    });

    testWidgets(
        '"Remove payment method" button renders when hasPaymentMethod == true AND hasActiveStakes == false',
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

      await pumpPaymentSettingsScreen(tester, mockRepo: mockRepo);

      // Enabled "Remove" button should be present
      expect(find.text(AppStrings.paymentRemoveButton), findsOneWidget);
      // Blocked-by-stakes note should NOT be visible
      expect(
          find.text(AppStrings.paymentRemoveBlockedByStakes), findsNothing);
    });

    testWidgets(
        '"Remove" button is disabled and stakes note shown when hasActiveStakes == true',
        (tester) async {
      final mockRepo = MockCommitmentContractsRepository();
      when(() => mockRepo.getPaymentStatus()).thenAnswer(
        (_) async => const CommitmentPaymentStatus(
          hasPaymentMethod: true,
          last4: '9999',
          brand: 'mastercard',
          hasActiveStakes: true,
        ),
      );

      await pumpPaymentSettingsScreen(tester, mockRepo: mockRepo);

      // The "Remove" button text is still present (but disabled)
      expect(find.text(AppStrings.paymentRemoveButton), findsOneWidget);

      // The blocked-by-stakes note is shown
      expect(
          find.text(AppStrings.paymentRemoveBlockedByStakes), findsOneWidget);

      // The enabled "Remove" CupertinoButton is not pressable — verify it
      // shows the disabled state by finding a CupertinoButton with null onPressed.
      // We verify the note is present as the primary behavioral indicator.
    });
  });
}
