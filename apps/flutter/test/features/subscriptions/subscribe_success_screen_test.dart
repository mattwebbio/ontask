// Widget tests for SubscribeSuccessScreen — Story 9.3 (AC: 2, 3, FR83).
// Tests activation callback handler: loading indicator, error dialog.
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/subscriptions/data/subscriptions_repository.dart';
import 'package:ontask/features/subscriptions/presentation/subscribe_success_screen.dart';
import 'package:ontask/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:ontask/features/subscriptions/domain/subscription_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Stub repository that simulates successful activation.
class _SuccessRepository extends SubscriptionsRepository {
  _SuccessRepository() : super(apiClient: ApiClient(baseUrl: 'http://fake'));

  @override
  Future<void> activateSubscription(String sessionId) async {
    // No-op: simulate successful activation.
  }

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return const SubscriptionStatus(state: SubscriptionState.active);
  }
}

// Stub repository that simulates activation failure.
class _FailRepository extends SubscriptionsRepository {
  _FailRepository() : super(apiClient: ApiClient(baseUrl: 'http://fake'));

  @override
  Future<void> activateSubscription(String sessionId) async {
    throw Exception('Activation failed');
  }

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return const SubscriptionStatus(state: SubscriptionState.expired);
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

  group('SubscribeSuccessScreen', () {
    testWidgets('renders CupertinoActivityIndicator while activating',
        (tester) async {
      final successRepo = _SuccessRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionsRepositoryProvider.overrideWithValue(successRepo),
            subscriptionStatusProvider.overrideWith(
              (_) async => const SubscriptionStatus(state: SubscriptionState.active),
            ),
          ],
          child: const CupertinoApp(
            home: SubscribeSuccessScreen(sessionId: 'test_session'),
          ),
        ),
      );
      // Before activation completes — screen should show loading indicator.
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets(
        'shows activation error dialog when activation fails',
        (tester) async {
      final failRepo = _FailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionsRepositoryProvider.overrideWithValue(failRepo),
            subscriptionStatusProvider.overrideWith(
              (_) async => const SubscriptionStatus(state: SubscriptionState.expired),
            ),
          ],
          child: const CupertinoApp(
            home: SubscribeSuccessScreen(sessionId: 'bad_session'),
          ),
        ),
      );
      // Pump a finite number of frames to let initState -> _activate() -> fail -> show dialog.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.subscriptionActivationError), findsOneWidget);
    });

    testWidgets(
        'activation error dialog has Retry action',
        (tester) async {
      final failRepo = _FailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionsRepositoryProvider.overrideWithValue(failRepo),
            subscriptionStatusProvider.overrideWith(
              (_) async => const SubscriptionStatus(state: SubscriptionState.expired),
            ),
          ],
          child: const CupertinoApp(
            home: SubscribeSuccessScreen(sessionId: 'bad_session'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
