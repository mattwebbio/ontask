// Widget tests for SubscriptionSettingsScreen — Story 9.1 (AC: 2, FR87).
// Uses ProviderScope override pattern from notification_centre_screen_test.dart.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
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
  });
}
