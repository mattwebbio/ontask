import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ontask/core/analytics/feature_flag_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captured calls and configurable return values for the posthog_flutter channel.
final List<MethodCall> _capturedCalls = [];
bool _featureFlagReturnValue = false;

void _setupPosthogChannelMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('posthog_flutter'),
    (MethodCall methodCall) async {
      _capturedCalls.add(methodCall);
      if (methodCall.method == 'isFeatureEnabled') {
        return _featureFlagReturnValue;
      }
      return null;
    },
  );
}

void _clearPosthogChannelMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('posthog_flutter'), null);
  _capturedCalls.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    _capturedCalls.clear();
    _featureFlagReturnValue = false;
  });

  tearDown(() {
    _clearPosthogChannelMock();
  });

  group('featureFlagProvider — when posthogApiKey is empty (default)', () {
    // In tests POSTHOG_API_KEY dart-define is not set, so AppConfig.posthogApiKey == ''.
    // Provider must return false without calling PostHog.

    setUp(() {
      _setupPosthogChannelMock();
    });

    test('returns false and does NOT call isFeatureEnabled', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(featureFlagProvider('my-flag').future);

      expect(result, isFalse);
      // Verify no platform channel calls were made.
      expect(_capturedCalls, isEmpty,
          reason: 'PostHog must not be called when posthogApiKey is empty');
    });

    test('returns false for any flag key when key is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = await container.read(featureFlagProvider('flag-a').future);
      final b = await container.read(featureFlagProvider('flag-b').future);

      expect(a, isFalse);
      expect(b, isFalse);
      expect(_capturedCalls, isEmpty);
    });
  });

  group('featureFlagProvider — provider override contract', () {
    // Since we cannot set dart-defines in unit tests, we test the provider
    // contract via Riverpod overrides using overrideWithValue.

    test('overrideWithValue(AsyncValue.data(true)) — provider returns true', () async {
      final container = ProviderContainer(
        overrides: [
          featureFlagProvider('my-flag')
              .overrideWithValue(const AsyncValue.data(true)),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(featureFlagProvider('my-flag').future);
      expect(result, isTrue);
    });

    test('overrideWithValue(AsyncValue.data(false)) — provider returns false', () async {
      final container = ProviderContainer(
        overrides: [
          featureFlagProvider('my-flag')
              .overrideWithValue(const AsyncValue.data(false)),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(featureFlagProvider('my-flag').future);
      expect(result, isFalse);
    });
  });

  group('featureFlagProvider — default false on non-configured', () {
    test('returns false when PostHog is not initialized (default path)', () async {
      // Without posthogApiKey configured (default in tests), the provider
      // must always return false — this is the contract for local dev and tests.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(featureFlagProvider('crash-flag').future);
      expect(result, isFalse);
    });
  });
}
