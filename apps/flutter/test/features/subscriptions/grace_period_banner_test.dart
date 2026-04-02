// Widget tests for GracePeriodBanner — Story 9.5 (AC: 1, FR90).
// Uses ProviderScope override pattern from trial_countdown_banner_test.dart.
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/features/subscriptions/domain/subscription_status.dart';
import 'package:ontask/features/subscriptions/presentation/grace_period_banner.dart';
import 'package:ontask/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('GracePeriodBanner', () {
    testWidgets('shows gracePeriodBannerText when status is gracePeriod', (tester) async {
      const gracePeriodStatus = SubscriptionStatus(
        state: SubscriptionState.gracePeriod,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => gracePeriodStatus),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: GracePeriodBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.gracePeriodBannerText), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when status is active', (tester) async {
      const activeStatus = SubscriptionStatus(state: SubscriptionState.active);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionStatusProvider.overrideWith((_) async => activeStatus),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: GracePeriodBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.gracePeriodBannerText), findsNothing);
    });
  });
}
