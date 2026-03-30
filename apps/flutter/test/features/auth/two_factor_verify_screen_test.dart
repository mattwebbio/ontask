import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/data/auth_repository.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/auth/presentation/two_factor_verify_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

/// Fake [AuthRepository] that returns a fixed [AuthResult] from [verify2FA].
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._result);
  final AuthResult _result;

  @override
  Future<AuthResult> verify2FA(String tempToken, String totpCode) async =>
      _result;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _stubTempToken = 'tmp_test_token_abc123';

Future<void> pumpTwoFactorVerifyScreen(
  WidgetTester tester, {
  required AuthResult verifyResult,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWith(
          () => _FakeAuthRepository(verifyResult),
        ),
        authStateProvider.overrideWithValue(
          const AuthResult.twoFactorRequired(tempToken: _stubTempToken),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const TwoFactorVerifyScreen(tempToken: _stubTempToken),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('TwoFactorVerifyScreen — rendering', () {
    testWidgets('shows verify instructions', (tester) async {
      await pumpTwoFactorVerifyScreen(
        tester,
        verifyResult: const AuthResult.unauthenticated(),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.twoFactorVerifyInstructions), findsOneWidget);
    });

    testWidgets('shows code input field', (tester) async {
      await pumpTwoFactorVerifyScreen(
        tester,
        verifyResult: const AuthResult.unauthenticated(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTextField), findsOneWidget);
    });

    testWidgets('shows verify button', (tester) async {
      await pumpTwoFactorVerifyScreen(
        tester,
        verifyResult: const AuthResult.unauthenticated(),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.twoFactorVerifyButton), findsOneWidget);
    });

    testWidgets('shows backup code affordance', (tester) async {
      await pumpTwoFactorVerifyScreen(
        tester,
        verifyResult: const AuthResult.unauthenticated(),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.twoFactorUseBackupCode), findsOneWidget);
    });
  });

  group('TwoFactorVerifyScreen — verification flow', () {
    testWidgets('shows error message when code is invalid', (tester) async {
      await pumpTwoFactorVerifyScreen(
        tester,
        verifyResult: const AuthResult.error(
          message:
              "That code isn't right. Check your authenticator app and try again.",
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoTextField), '999999');
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.twoFactorVerifyButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("That code isn't right"),
        findsOneWidget,
      );
    });

    testWidgets(
        'verify button calls verify2FA with temp token and entered code',
        (tester) async {
      // Track the code that was passed to verify2FA.
      String? capturedCode;
      String? capturedToken;

      final fakeRepo = _TrackingAuthRepository(
        onVerify2FA: (token, code) {
          capturedToken = token;
          capturedCode = code;
          // Return unauthenticated so authStateProvider.notifier.setAuthenticated
          // is NOT called (avoids the overrideWithValue + .notifier conflict).
          return const AuthResult.unauthenticated();
        },
      );

      // Do NOT override authStateProvider with a value here — the screen calls
      // authStateProvider.notifier which requires the real notifier.
      // The real AuthStateNotifier is used with FlutterSecureStorage mocked empty,
      // so it starts unauthenticated (no token). That is fine for this test.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith(() => fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const TwoFactorVerifyScreen(tempToken: _stubTempToken),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(CupertinoTextField), '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.twoFactorVerifyButton));
      await tester.pumpAndSettle();

      expect(capturedToken, equals(_stubTempToken));
      expect(capturedCode, equals('123456'));
    });
  });
}

/// A tracking [AuthRepository] fake that captures [verify2FA] arguments.
class _TrackingAuthRepository extends AuthRepository {
  _TrackingAuthRepository({required this.onVerify2FA});

  final AuthResult Function(String token, String code) onVerify2FA;

  @override
  Future<AuthResult> verify2FA(String tempToken, String totpCode) async =>
      onVerify2FA(tempToken, totpCode);
}
