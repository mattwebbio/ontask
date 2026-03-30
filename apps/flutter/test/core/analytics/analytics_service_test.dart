import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake PosthogClient — records calls synchronously without any platform channel.
// Avoids MissingPluginException on Linux CI where posthog_flutter has no
// platform implementation.
// ---------------------------------------------------------------------------
class _FakePosthogClient implements PosthogClient {
  final List<Map<String, dynamic>> calls = [];

  @override
  void capture(String eventName, Map<String, Object> properties) =>
      calls.add({'method': 'capture', 'eventName': eventName, 'properties': properties});

  @override
  void identify(String userId) =>
      calls.add({'method': 'identify', 'userId': userId});

  @override
  void reset() => calls.add({'method': 'reset'});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsService — provider instantiation', () {
    test('analyticsServiceProvider creates an AnalyticsService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(analyticsServiceProvider);
      expect(service, isA<AnalyticsService>());
    });

    test('two reads return the same instance (keepAlive)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(analyticsServiceProvider);
      final b = container.read(analyticsServiceProvider);
      expect(a, same(b));
    });
  });

  group('AnalyticsService — no-ops when posthogApiKey is empty (default)', () {
    // In tests POSTHOG_API_KEY dart-define is not set, so AppConfig.posthogApiKey == ''.
    // All methods must be silent no-ops — no client calls made.

    late _FakePosthogClient fakeClient;

    setUp(() {
      fakeClient = _FakePosthogClient();
    });

    test('isEnabled returns false when posthogApiKey is empty', () {
      final service = AnalyticsService(client: fakeClient);
      expect(service.isEnabled, isFalse);
    });

    test('track() does NOT call PostHog capture when key is empty', () {
      final service = AnalyticsService(client: fakeClient);
      service.track('test_event', properties: {'foo': 'bar'});

      expect(fakeClient.calls, isEmpty);
    });

    test('identify() does NOT call PostHog identify when key is empty', () {
      final service = AnalyticsService(client: fakeClient);
      service.identify('user-uuid-1234');

      expect(fakeClient.calls, isEmpty);
    });

    test('reset() does NOT call PostHog reset when key is empty', () {
      final service = AnalyticsService(client: fakeClient);
      service.reset();

      expect(fakeClient.calls, isEmpty);
    });
  });

  group('AnalyticsService — PII contract (isEnabled: true)', () {
    // Tests the actual client call path with isEnabled forced true so we can
    // verify behaviour without dart-defines.

    late _FakePosthogClient fakeClient;
    late AnalyticsService service;

    setUp(() {
      fakeClient = _FakePosthogClient();
      service = AnalyticsService(client: fakeClient, isEnabled: true);
    });

    test('identify() passes only userId — no email, name, or extra properties', () {
      service.identify('user-uuid-5678');

      final identifyCall = fakeClient.calls.firstWhere(
        (c) => c['method'] == 'identify',
        orElse: () => throw TestFailure('No identify call captured'),
      );

      expect(identifyCall['userId'], equals('user-uuid-5678'),
          reason: 'userId must be the provided UUID');
      // No email, name, or payment fields must be present.
      expect(identifyCall.containsKey('email'), isFalse,
          reason: 'email must NOT be passed to identify()');
      expect(identifyCall.containsKey('name'), isFalse,
          reason: 'name must NOT be passed to identify()');
    });

    test('track() forwards event name to PostHog capture', () {
      service.track('task_completed', properties: {'task_id': 'abc-123'});

      final captureCall = fakeClient.calls.firstWhere(
        (c) => c['method'] == 'capture',
        orElse: () => throw TestFailure('No capture call captured'),
      );

      expect(captureCall['eventName'], equals('task_completed'));
    });

    test('reset() calls PostHog reset method', () {
      service.reset();

      final resetCall = fakeClient.calls.firstWhere(
        (c) => c['method'] == 'reset',
        orElse: () => throw TestFailure('No reset call captured'),
      );

      expect(resetCall['method'], equals('reset'));
    });
  });
}
