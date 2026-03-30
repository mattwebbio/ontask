import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/data/auth_repository.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/settings/data/settings_repository.dart';
import 'package:ontask/features/settings/presentation/delete_account_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSettingsRepository extends Mock implements SettingsRepository {}
class MockApiClient extends Mock implements ApiClient {}

// ── Fakes ─────────────────────────────────────────────────────────────────────

/// Fake [AuthRepository] with a no-op [signOut] for test isolation.
class _FakeAuthRepository extends AuthRepository {
  @override
  Future<void> signOut() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pumps [DeleteAccountScreen] with mocked repositories.
///
/// Uses the real [AuthStateNotifier] so that [authStateProvider.notifier.signOut()] works.
/// The underlying [AuthRepository] is a fake with no-op [signOut].
Future<void> pumpDeleteAccountScreen(
  WidgetTester tester, {
  required MockSettingsRepository mockSettingsRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        authRepositoryProvider.overrideWith(() => _FakeAuthRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const DeleteAccountScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Provide an access token so AuthStateNotifier starts authenticated.
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'stub_access_token',
    });
    SharedPreferences.setMockInitialValues({
      'auth_was_authenticated': true,
    });
    SharedPreferences.getInstance().then(AuthStateNotifier.prewarmPrefs);
    registerFallbackValue('');
  });

  group('DeleteAccountScreen — confirmation text match', () {
    testWidgets('CTA is disabled when text field is empty', (tester) async {
      final settingsRepo = MockSettingsRepository();
      await pumpDeleteAccountScreen(tester, mockSettingsRepo: settingsRepo);

      expect(find.text(AppStrings.deleteAccountButton), findsOneWidget);
      verifyNever(() => settingsRepo.deleteAccount());
    });

    testWidgets('CTA is disabled when text does not match exactly', (tester) async {
      final settingsRepo = MockSettingsRepository();
      await pumpDeleteAccountScreen(tester, mockSettingsRepo: settingsRepo);

      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'wrong text',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(AppStrings.deleteAccountButton),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      verifyNever(() => settingsRepo.deleteAccount());
    });

    testWidgets(
        'CTA is disabled when confirmation text has different casing (case-sensitive)',
        (tester) async {
      final settingsRepo = MockSettingsRepository();
      await pumpDeleteAccountScreen(tester, mockSettingsRepo: settingsRepo);

      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'DELETE MY ACCOUNT',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(AppStrings.deleteAccountButton),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      verifyNever(() => settingsRepo.deleteAccount());
    });

    testWidgets(
        'CTA calls deleteAccount() when exact confirmation text is typed',
        (tester) async {
      final settingsRepo = MockSettingsRepository();
      when(() => settingsRepo.deleteAccount()).thenAnswer((_) async {});
      await pumpDeleteAccountScreen(tester, mockSettingsRepo: settingsRepo);

      await tester.enterText(
        find.byType(CupertinoTextField).first,
        AppStrings.deleteAccountConfirmMatch, // "delete my account"
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.deleteAccountButton));
      await tester.pumpAndSettle();

      verify(() => settingsRepo.deleteAccount()).called(1);
    });
  });

  group('DeleteAccountScreen — post-deletion', () {
    testWidgets(
        'deleteAccount() is called and farewell screen shown on success',
        (tester) async {
      final settingsRepo = MockSettingsRepository();
      when(() => settingsRepo.deleteAccount()).thenAnswer((_) async {});

      await pumpDeleteAccountScreen(tester, mockSettingsRepo: settingsRepo);

      await tester.enterText(
        find.byType(CupertinoTextField).first,
        AppStrings.deleteAccountConfirmMatch,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.deleteAccountButton));
      await tester.pumpAndSettle();

      // deleteAccount() must have been called.
      verify(() => settingsRepo.deleteAccount()).called(1);

      // FarewellScreen is pushed after sign-out.
      expect(find.text(AppStrings.farewellTitle), findsOneWidget);
    });
  });
}
