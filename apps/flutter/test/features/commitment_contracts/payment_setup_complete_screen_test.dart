// Widget tests for PaymentSetupCompleteScreen — Story 13.1.
// Tests the Universal Link callback handler for payment method setup.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';
import 'package:ontask/features/commitment_contracts/domain/commitment_payment_status.dart';
import 'package:ontask/features/commitment_contracts/presentation/payment_setup_complete_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Stub repository that simulates successful setup confirmation.
class _SuccessRepository extends CommitmentContractsRepository {
  _SuccessRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<CommitmentPaymentStatus> confirmSetup(String sessionToken) async {
    return const CommitmentPaymentStatus(
      hasPaymentMethod: true,
      last4: '4242',
      brand: 'visa',
      hasActiveStakes: false,
    );
  }
}

// Stub repository that simulates setup confirmation failure.
class _FailRepository extends CommitmentContractsRepository {
  _FailRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<CommitmentPaymentStatus> confirmSetup(String sessionToken) async {
    throw Exception('Confirmation failed');
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('PaymentSetupCompleteScreen', () {
    testWidgets('shows CupertinoActivityIndicator while confirming',
        (tester) async {
      final successRepo = _SuccessRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commitmentContractsRepositoryProvider.overrideWithValue(successRepo),
          ],
          child: const CupertinoApp(
            home: PaymentSetupCompleteScreen(sessionToken: 'valid_token'),
          ),
        ),
      );
      // Before confirmation completes — screen should show loading indicator.
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('shows error dialog when sessionToken is empty',
        (tester) async {
      final successRepo = _SuccessRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commitmentContractsRepositoryProvider.overrideWithValue(successRepo),
          ],
          child: const CupertinoApp(
            home: PaymentSetupCompleteScreen(sessionToken: ''),
          ),
        ),
      );
      // Empty session token — error dialog should appear immediately.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.paymentSetupConfirmError), findsOneWidget);
    });

    testWidgets('shows error dialog when confirmation fails', (tester) async {
      final failRepo = _FailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commitmentContractsRepositoryProvider.overrideWithValue(failRepo),
          ],
          child: const CupertinoApp(
            home: PaymentSetupCompleteScreen(sessionToken: 'invalid_token'),
          ),
        ),
      );
      // Pump frames to let initState → _confirm() → throw → _showError() run.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.paymentSetupConfirmError), findsOneWidget);
    });

    testWidgets('error dialog has Retry action', (tester) async {
      final failRepo = _FailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commitmentContractsRepositoryProvider.overrideWithValue(failRepo),
          ],
          child: const CupertinoApp(
            home: PaymentSetupCompleteScreen(sessionToken: 'invalid_token'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('error dialog has OK action', (tester) async {
      final failRepo = _FailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commitmentContractsRepositoryProvider.overrideWithValue(failRepo),
          ],
          child: const CupertinoApp(
            home: PaymentSetupCompleteScreen(sessionToken: 'invalid_token'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.actionOk), findsOneWidget);
    });

    testWidgets('on successful confirmation navigates to /settings/payments',
        (tester) async {
      // Uses GoRouter so context.go('/settings/payments') can resolve.
      final successRepo = _SuccessRepository();
      final router = GoRouter(
        initialLocation: '/payment-setup-complete',
        routes: [
          GoRoute(
            path: '/payment-setup-complete',
            builder: (context, _) => const PaymentSetupCompleteScreen(
              sessionToken: 'valid_token',
            ),
          ),
          GoRoute(
            path: '/settings/payments',
            builder: (context, _) => const Scaffold(
              body: Center(child: Text('Payments Settings')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commitmentContractsRepositoryProvider.overrideWithValue(successRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Pump once to start initState → _confirm() async call.
      await tester.pump();
      // Pump to let the Future complete and navigation occur.
      await tester.pump(const Duration(milliseconds: 100));

      // After successful confirmation the router should have navigated to
      // /settings/payments — the placeholder page text should be visible.
      expect(find.text('Payments Settings'), findsOneWidget);
    });
  });
}
