// Widget tests for PaywallScreen — Story 9.2 (AC: 1, 2, FR88).
// Uses ProviderScope override pattern from subscription_settings_screen_test.dart.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/features/subscriptions/domain/subscription_status.dart';
import 'package:ontask/features/subscriptions/presentation/paywall_screen.dart';
import 'package:ontask/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('PaywallScreen', () {
    testWidgets('renders without errors when subscription is expired',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // No errors thrown — screen rendered successfully.
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('paywall headline text is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallHeadline), findsOneWidget);
    });

    testWidgets('individual tier name is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallTierIndividualName), findsOneWidget);
    });

    testWidgets('couple tier name is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallTierCoupleName), findsOneWidget);
    });

    testWidgets('family & friends tier name is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallTierFamilyName), findsOneWidget);
    });

    testWidgets('at least one Subscribe button is present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallSubscribeCta), findsWidgets);
    });

    testWidgets('restore purchase button is present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Scroll down to reveal items below the fold.
      await tester.scrollUntilVisible(
        find.text(AppStrings.paywallRestorePurchase),
        200,
      );
      expect(find.text(AppStrings.paywallRestorePurchase), findsOneWidget);
    });

    testWidgets('cancellation terms text is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Scroll down to reveal items below the fold.
      await tester.scrollUntilVisible(
        find.text(AppStrings.paywallCancellationTerms),
        200,
      );
      expect(find.text(AppStrings.paywallCancellationTerms), findsOneWidget);
    });

    testWidgets('individual tier price text is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => _expiredStatus),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallTierIndividualPrice), findsOneWidget);
    });

    testWidgets('renders correctly when subscriptionStatusProvider is in AsyncLoading state (no crash)',
        (tester) async {
      final completer = Completer<SubscriptionStatus>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) => completer.future),
          ],
          child: const CupertinoApp(home: PaywallScreen()),
        ),
      );
      await tester.pump();
      // Screen renders without crash even while provider is loading.
      expect(find.byType(PaywallScreen), findsOneWidget);
      completer.complete(_expiredStatus);
      await tester.pumpAndSettle();
    });
  });
}
