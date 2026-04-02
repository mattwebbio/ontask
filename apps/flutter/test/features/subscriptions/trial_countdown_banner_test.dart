// Widget tests for TrialCountdownBanner — Story 9.1 (AC: 2).
// Uses ProviderScope override pattern from notification_centre_screen_test.dart.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/features/subscriptions/domain/subscription_status.dart';
import 'package:ontask/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:ontask/features/subscriptions/presentation/trial_countdown_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

SubscriptionStatus _trialingStatus({required int days}) => SubscriptionStatus(
      state: SubscriptionState.trialing,
      trialStartedAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(Duration(days: days)),
      trialDaysRemaining: days,
    );

const _activeStatus = SubscriptionStatus(
  state: SubscriptionState.active,
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('TrialCountdownBanner', () {
    testWidgets(
        'banner is not visible when trialDaysRemaining = 14 (outside 3-day window)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _trialingStatus(days: 14)),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: TrialCountdownBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trialCountdownBannerText(14)), findsNothing);
    });

    testWidgets('banner is visible when trialDaysRemaining = 3', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _trialingStatus(days: 3)),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: TrialCountdownBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trialCountdownBannerText(3)), findsOneWidget);
    });

    testWidgets('banner is visible when trialDaysRemaining = 1', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _trialingStatus(days: 1)),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: TrialCountdownBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trialCountdownBannerText(1)), findsOneWidget);
    });

    testWidgets(
        'banner shows correct text from trialCountdownBannerText(2) when trialDaysRemaining = 2',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _trialingStatus(days: 2)),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: TrialCountdownBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trialCountdownBannerText(2)), findsOneWidget);
      expect(
        find.text(
            '2 days left in your free trial \u2014 subscribe to keep access'),
        findsOneWidget,
      );
    });

    testWidgets('banner is not visible when subscription state is active',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _activeStatus),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: TrialCountdownBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Active state: showTrialCountdownBanner = false → SizedBox.shrink, no Container
      expect(find.byType(Container), findsNothing);
    });

    testWidgets(
        'banner is not visible when subscriptionStatusProvider is in error state',
        (tester) async {
      final completer = Completer<SubscriptionStatus>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) => completer.future),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: TrialCountdownBanner()),
          ),
        ),
      );
      await tester.pump();
      // Complete with error
      completer.completeError(Exception('Network error'));
      await tester.pumpAndSettle();
      // On error: banner renders SizedBox.shrink — no banner Container visible
      expect(find.byType(Container), findsNothing);
    });
  });
}
