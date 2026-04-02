// Widget tests for SubscriptionSettingsScreen — Story 9.1 (AC: 2, FR87).
// Uses ProviderScope override pattern from notification_centre_screen_test.dart.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/subscriptions/data/subscriptions_repository.dart';
import 'package:ontask/features/subscriptions/domain/subscription_status.dart';
import 'package:ontask/features/subscriptions/presentation/subscription_settings_screen.dart';
import 'package:ontask/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SubscriptionStatus _trialingStatus({int days = 14}) => SubscriptionStatus(
      state: SubscriptionState.trialing,
      trialStartedAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(Duration(days: days)),
      trialDaysRemaining: days,
    );

const _expiredStatus = SubscriptionStatus(
  state: SubscriptionState.expired,
);

/// Fake repository for cancel CTA tests (Story 9.4).
/// Records cancelSubscription call count so tests can verify invocation.
class _FakeSubscriptionsRepository extends SubscriptionsRepository {
  _FakeSubscriptionsRepository()
      : super(apiClient: _NoOpApiClient());

  int cancelCallCount = 0;

  @override
  Future<void> cancelSubscription() async {
    cancelCallCount++;
  }

  @override
  Future<void> restoreSubscription() async {}

  @override
  Future<void> activateSubscription(String sessionId) async {}

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async =>
      const SubscriptionStatus(state: SubscriptionState.active);
}

/// Minimal ApiClient stub — never used in fake repository methods.
class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('SubscriptionSettingsScreen', () {
    testWidgets('loading state shows CupertinoActivityIndicator', (tester) async {
      final completer = Completer<SubscriptionStatus>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) => completer.future),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      completer.complete(_trialingStatus());
      await tester.pumpAndSettle();
    });

    testWidgets('trialing state shows subscriptionTrialDaysRemaining(14) text',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _trialingStatus(days: 14)),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.subscriptionTrialDaysRemaining(14)),
        findsOneWidget,
      );
    });

    testWidgets(
        'trialing state with trialDaysRemaining=1 shows singular "1 day remaining" text',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _trialingStatus(days: 1)),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.subscriptionTrialDaysRemaining(1)),
        findsOneWidget,
      );
      expect(find.text('1 day remaining in your free trial'), findsOneWidget);
    });

    testWidgets('expired state shows subscriptionExpiredLabel text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.subscriptionExpiredLabel), findsOneWidget);
    });

    // Deferred from Story 9.1 code review — error branch was missing coverage.
    testWidgets('error state shows subscriptionSettingsLoadError text',
        (tester) async {
      final completer = Completer<SubscriptionStatus>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) => completer.future),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pump();
      // Drive the provider into error state.
      completer.completeError(Exception('test error'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.subscriptionSettingsLoadError), findsOneWidget);
    });

    // Story 9.3 tests: active subscription state UI.

    testWidgets(
        'active state renders subscriptionActiveStatusLabel text',
        (tester) async {
      const activeStatus = SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: null,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => activeStatus),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.subscriptionActiveStatusLabel),
        findsOneWidget,
      );
    });

    testWidgets(
        'active state renders subscriptionManageCta button',
        (tester) async {
      const activeStatus = SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: null,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => activeStatus),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.subscriptionManageCta), findsOneWidget);
    });

    testWidgets(
        'active state with renewal date shows formatted renewal date',
        (tester) async {
      final activeStatus = SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => activeStatus),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Renewal date should be displayed in formatted form.
      expect(
        find.text(AppStrings.subscriptionRenewalDate('2026-05-01')),
        findsOneWidget,
      );
    });

    // Story 9.4 tests: cancelled state UI.

    const _cancelledStatus = SubscriptionStatus(
      state: SubscriptionState.cancelled,
      currentPeriodEnd: null,
    );

    testWidgets('cancelled state renders subscriptionCancelledStatusLabel text',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => _cancelledStatus),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.subscriptionCancelledStatusLabel), findsOneWidget);
    });

    testWidgets('cancelled state renders subscriptionReactivateCta button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => _cancelledStatus),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.subscriptionReactivateCta), findsOneWidget);
    });

    testWidgets(
        'cancelled state with currentPeriodEnd shows formatted access-until date',
        (tester) async {
      final cancelledWithDate = SubscriptionStatus(
        state: SubscriptionState.cancelled,
        currentPeriodEnd: DateTime(2026, 6, 15),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => cancelledWithDate),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.subscriptionActiveUntil('2026-06-15')),
        findsOneWidget,
      );
    });

    // Story 9.4 tests: active state cancel CTA.

    testWidgets('active state renders subscriptionCancelConfirmAction text button',
        (tester) async {
      const activeStatus = SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: null,
      );
      final fakeRepo = _FakeSubscriptionsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => activeStatus),
            subscriptionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.subscriptionCancelConfirmAction), findsOneWidget);
    });

    testWidgets(
        'tapping cancel CTA shows confirmation dialog with subscriptionCancelConfirmTitle',
        (tester) async {
      const activeStatus = SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: null,
      );
      final fakeRepo = _FakeSubscriptionsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => activeStatus),
            subscriptionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Tap the cancel CTA button.
      await tester.tap(find.text(AppStrings.subscriptionCancelConfirmAction));
      await tester.pumpAndSettle();
      // Confirmation dialog should appear.
      expect(find.text(AppStrings.subscriptionCancelConfirmTitle), findsOneWidget);
    });

    testWidgets(
        'dismissing confirmation dialog (Keep Subscription) does NOT call cancelSubscription',
        (tester) async {
      const activeStatus = SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: null,
      );
      final fakeRepo = _FakeSubscriptionsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => activeStatus),
            subscriptionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const CupertinoApp(home: SubscriptionSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Tap the cancel CTA button.
      await tester.tap(find.text(AppStrings.subscriptionCancelConfirmAction));
      await tester.pumpAndSettle();
      // Dialog visible — tap dismiss.
      await tester.tap(find.text(AppStrings.subscriptionCancelConfirmDismiss));
      await tester.pumpAndSettle();
      // cancelSubscription should NOT have been called.
      expect(fakeRepo.cancelCallCount, 0);
    });
  });
}
