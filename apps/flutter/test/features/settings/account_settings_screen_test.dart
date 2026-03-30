import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/settings/data/settings_repository.dart';
import 'package:ontask/features/settings/presentation/account_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSettingsRepository extends Mock implements SettingsRepository {}
class MockApiClient extends Mock implements ApiClient {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> pumpAccountSettingsScreen(
  WidgetTester tester, {
  required AuthResult authState,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(authState),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const AccountSettingsScreen(),
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
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('AccountSettingsScreen — tile visibility', () {
    testWidgets('shows Export Data tile', (tester) async {
      await pumpAccountSettingsScreen(
        tester,
        authState: const AuthResult.authenticated(userId: 'user_1'),
      );

      expect(find.text(AppStrings.accountExportData), findsOneWidget);
    });

    testWidgets('shows Delete Account tile', (tester) async {
      await pumpAccountSettingsScreen(
        tester,
        authState: const AuthResult.authenticated(userId: 'user_1'),
      );

      expect(find.text(AppStrings.accountDeleteAccount), findsOneWidget);
    });

    testWidgets('shows 2FA tile for authenticated (email) users', (tester) async {
      // Authenticated state represents email users in the current stub implementation.
      await pumpAccountSettingsScreen(
        tester,
        authState: const AuthResult.authenticated(userId: 'user_1'),
      );

      expect(find.text(AppStrings.accountTwoFactorAuth), findsOneWidget);
    });

    testWidgets('hides 2FA tile when user is unauthenticated', (tester) async {
      // Unauthenticated state represents OAuth users or signed-out users.
      // 2FA tile must not be shown (NFR-S8: only email/password accounts).
      await pumpAccountSettingsScreen(
        tester,
        authState: const AuthResult.unauthenticated(),
      );

      expect(find.text(AppStrings.accountTwoFactorAuth), findsNothing);
    });

    testWidgets('hides 2FA tile when state is twoFactorRequired', (tester) async {
      // During 2FA login challenge, account screen should not offer 2FA setup.
      await pumpAccountSettingsScreen(
        tester,
        authState:
            const AuthResult.twoFactorRequired(tempToken: 'tmp_abc'),
      );

      expect(find.text(AppStrings.accountTwoFactorAuth), findsNothing);
    });
  });

  group('AccountSettingsScreen — navigation', () {
    testWidgets('tapping Export Data navigates to ExportDataScreen',
        (tester) async {
      await pumpAccountSettingsScreen(
        tester,
        authState: const AuthResult.authenticated(userId: 'user_1'),
      );

      await tester.tap(find.text(AppStrings.accountExportData));
      await tester.pumpAndSettle();

      // ExportDataScreen is now visible — the description text is unique to it.
      expect(find.text(AppStrings.exportDataDescription), findsOneWidget);
    });

    testWidgets('tapping Delete Account navigates to DeleteAccountScreen',
        (tester) async {
      await pumpAccountSettingsScreen(
        tester,
        authState: const AuthResult.authenticated(userId: 'user_1'),
      );

      await tester.tap(find.text(AppStrings.accountDeleteAccount));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.deleteAccountTitle), findsOneWidget);
    });
  });
}
