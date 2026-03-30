import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthStateNotifier — isOnboardingCompleted', () {
    test('returns false by default when SharedPreferences has no key', () async {
      final prefs = await SharedPreferences.getInstance();
      // Ensure key is absent
      await prefs.remove(kOnboardingCompleted);

      // Prewarm the notifier with our prefs instance
      AuthStateNotifier.prewarmPrefs(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      expect(notifier.isOnboardingCompleted, isFalse);
    });

    test('returns true when kOnboardingCompleted is set to true', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingCompleted, true);
      AuthStateNotifier.prewarmPrefs(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      expect(notifier.isOnboardingCompleted, isTrue);
    });
  });

  group('AuthStateNotifier — completeOnboarding()', () {
    test('sets kOnboardingCompleted to true in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      AuthStateNotifier.prewarmPrefs(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);

      // Before calling completeOnboarding, key should be absent
      expect(prefs.getBool(kOnboardingCompleted), isNull);

      // completeOnboarding sets the key synchronously before the API call
      // The API call will fail silently in tests (no real network) — that's expected.
      await notifier.completeOnboarding();

      expect(prefs.getBool(kOnboardingCompleted), isTrue);
    });

    test('isOnboardingCompleted reflects true after completeOnboarding()', () async {
      final prefs = await SharedPreferences.getInstance();
      AuthStateNotifier.prewarmPrefs(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      expect(notifier.isOnboardingCompleted, isFalse);

      await notifier.completeOnboarding();
      expect(notifier.isOnboardingCompleted, isTrue);
    });
  });
}
