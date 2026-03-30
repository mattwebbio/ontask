import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captured method channel calls for assertion.
final List<MethodCall> _capturedCalls = [];

/// Sets up a method channel mock for the 'posthog_flutter' channel.
///
/// All calls are recorded in [_capturedCalls]. Pass [returnValue] for methods
/// that need a specific return value (e.g. isFeatureEnabled → true/false).
void _setupPosthogChannelMock({dynamic returnValue}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('posthog_flutter'),
    (MethodCall methodCall) async {
      _capturedCalls.add(methodCall);
      return returnValue;
    },
  );
}

void _clearPosthogChannelMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('posthog_flutter'), null);
  _capturedCalls.clear();
}

// ---------------------------------------------------------------------------
// Test-only subclass that bypasses AppConfig.posthogApiKey guard so we can
// test the actual PostHog call path without dart-defines.
// ---------------------------------------------------------------------------
class _EnabledAnalyticsService extends AnalyticsService {
  const _EnabledAnalyticsService();

  @override
  bool get isEnabled => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    _capturedCalls.clear();
  });

  tearDown(() {
    _clearPosthogChannelMock();
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
    // All methods must be silent no-ops — no platform channel calls.

    setUp(() {
      _setupPosthogChannelMock();
    });

    test('isEnabled returns false when posthogApiKey is empty', () {
      const service = AnalyticsService();
      expect(service.isEnabled, isFalse);
    });

    test('track() does NOT call PostHog capture when key is empty', () {
      const service = AnalyticsService();
      service.track('test_event', properties: {'foo': 'bar'});

      expect(_capturedCalls, isEmpty);
    });

    test('identify() does NOT call PostHog identify when key is empty', () {
      const service = AnalyticsService();
      service.identify('user-uuid-1234');

      expect(_capturedCalls, isEmpty);
    });

    test('reset() does NOT call PostHog reset when key is empty', () {
      const service = AnalyticsService();
      service.reset();

      expect(_capturedCalls, isEmpty);
    });
  });

  group('AnalyticsService — PII contract (via _EnabledAnalyticsService)', () {
    // Tests the actual PostHog call path using the test subclass that bypasses
    // the posthogApiKey guard.

    setUp(() {
      _setupPosthogChannelMock();
    });

    test('identify() passes only userId — no email, name, or extra properties', () async {
      const service = _EnabledAnalyticsService();
      service.identify('user-uuid-5678');

      // Allow the async method channel call to complete.
      await Future<void>.delayed(Duration.zero);

      final identifyCall = _capturedCalls.firstWhere(
        (c) => c.method == 'identify',
        orElse: () => throw TestFailure('No identify call captured'),
      );

      final args = identifyCall.arguments as Map;
      expect(args['userId'], equals('user-uuid-5678'),
          reason: 'userId must be the provided UUID');
      // No email, name, or payment fields must be present.
      expect(args.containsKey('email'), isFalse,
          reason: 'email must NOT be passed to identify()');
      expect(args.containsKey('name'), isFalse,
          reason: 'name must NOT be passed to identify()');
    });

    test('track() forwards event name to PostHog capture', () async {
      const service = _EnabledAnalyticsService();
      service.track('task_completed', properties: {'task_id': 'abc-123'});

      await Future<void>.delayed(Duration.zero);

      final captureCall = _capturedCalls.firstWhere(
        (c) => c.method == 'capture',
        orElse: () => throw TestFailure('No capture call captured'),
      );

      final args = captureCall.arguments as Map;
      expect(args['eventName'], equals('task_completed'));
    });

    test('reset() calls PostHog reset method', () async {
      const service = _EnabledAnalyticsService();
      service.reset();

      await Future<void>.delayed(Duration.zero);

      final resetCall = _capturedCalls.firstWhere(
        (c) => c.method == 'reset',
        orElse: () => throw TestFailure('No reset call captured'),
      );

      expect(resetCall.method, equals('reset'));
    });
  });
}
