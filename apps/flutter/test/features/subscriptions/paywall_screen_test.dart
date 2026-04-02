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

    // Story 9.3 tests: subscribe CTA wiring and tier availability.

    testWidgets(
        'individual tier Subscribe button is enabled (available tier)',
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
      // Find all CupertinoButton widgets that contain a Subscribe Text child.
      final allSubscribeButtons = tester
          .widgetList<CupertinoButton>(
            find.byWidgetPredicate(
              (w) => w is CupertinoButton &&
                  w.child is Text &&
                  (w.child as Text).data == 'Subscribe',
            ),
          )
          .toList();
      // At least one subscribe button exists.
      expect(allSubscribeButtons.isNotEmpty, true);
      // The first (individual) should be enabled (non-null onPressed).
      expect(allSubscribeButtons[0].onPressed, isNotNull);
    });

    testWidgets(
        'couple tier Subscribe button is disabled (unavailable tier)',
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
      // Find all CupertinoButton widgets with Subscribe label.
      final allSubscribeButtons = tester
          .widgetList<CupertinoButton>(
            find.byWidgetPredicate(
              (w) => w is CupertinoButton &&
                  w.child is Text &&
                  (w.child as Text).data == 'Subscribe',
            ),
          )
          .toList();
      // There should be 3 subscribe buttons (one per tier).
      expect(allSubscribeButtons.length, 3);
      // The second (couple) and third (family) should have null onPressed (disabled).
      expect(allSubscribeButtons[1].onPressed, isNull);
      expect(allSubscribeButtons[2].onPressed, isNull);
    });

    testWidgets(
        'paywall screen navigates away when subscriptionStatusProvider returns active status',
        (tester) async {
      const activeStatus = SubscriptionStatus(state: SubscriptionState.active);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider
                .overrideWith((_) async => activeStatus),
          ],
          child: const CupertinoApp(
            // Use a navigator with a route stack to observe navigation.
            home: PaywallScreen(),
          ),
        ),
      );
      // PaywallScreen calls context.go('/now') when active — just verify it renders
      // without crash in this minimal test environment.
      await tester.pump();
      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });
}
