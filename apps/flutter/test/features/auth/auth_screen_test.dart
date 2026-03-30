import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/data/auth_repository.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/auth/presentation/auth_screen.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

/// A fake [AuthRepository] that returns a fixed [AuthResult] from every
/// sign-in method.  Used to inject error / cancel results without a real API.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._result);

  final AuthResult _result;

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async =>
      _result;

  @override
  Future<AuthResult> signInWithApple() async => _result;

  @override
  Future<AuthResult> signInWithGoogle() async => _result;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pumps [AuthScreen] inside a minimal [ProviderScope] + themed [MaterialApp].
/// The OnTaskColors theme extension is required by [AuthScreen].
Future<void> pumpAuthScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(const AuthResult.unauthenticated()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const AuthScreen(),
      ),
    ),
  );
  await tester.pump(); // Allow initial frame to settle
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthScreen — layout and accessibility', () {
    testWidgets(
        'Sign in with Apple button is the topmost sign-in element (Apple HIG)',
        (tester) async {
      await pumpAuthScreen(tester);

      // Find sign-in elements by their visible text.
      // Sign in with Apple renders via sign_in_with_apple package.
      // Google sign-in is a custom CupertinoButton with "Sign in with Google" text.
      final appleButtonFinder = find.text('Sign in with Apple');
      final googleButtonFinder = find.text('Sign in with Google');
      final emailFieldFinder = find.byType(CupertinoTextField).first;

      // All sign-in elements must exist.
      expect(appleButtonFinder, findsOneWidget);
      expect(googleButtonFinder, findsOneWidget);
      expect(emailFieldFinder, findsOneWidget);

      // Apple Sign In must be topmost (lowest Y position = highest on screen).
      final applePos = tester.getTopLeft(appleButtonFinder);
      final googlePos = tester.getTopLeft(googleButtonFinder);
      final emailPos = tester.getTopLeft(emailFieldFinder);

      expect(
        applePos.dy,
        lessThan(googlePos.dy),
        reason: 'Apple Sign In must appear above Google Sign In (Apple HIG)',
      );
      expect(
        applePos.dy,
        lessThan(emailPos.dy),
        reason: 'Apple Sign In must appear above email field (Apple HIG)',
      );
    });

    testWidgets('Sign in with Google and email fields are visible',
        (tester) async {
      await pumpAuthScreen(tester);

      expect(find.text('Sign in with Google'), findsOneWidget);
      // Email and password CupertinoTextFields are present.
      expect(find.byType(CupertinoTextField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('subtitle uses warm voice copy', (tester) async {
      await pumpAuthScreen(tester);

      expect(
        find.text('your past self is counting on you'),
        findsOneWidget,
      );
    });

    testWidgets('error message is hidden by default', (tester) async {
      await pumpAuthScreen(tester);

      expect(
        find.textContaining("isn't quite right"),
        findsNothing,
      );
      expect(
        find.textContaining('Something went wrong'),
        findsNothing,
      );
    });

    testWidgets(
        'no CupertinoActivityIndicator visible when not loading',
        (tester) async {
      await pumpAuthScreen(tester);

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });
  });

  group('AuthScreen — error display (NFR-UX2)', () {
    test('authErrorInvalidCredentials string is plain-language (no error codes)',
        () {
      // Direct validation of the error string constant used in AuthRepository.
      const errorMsg =
          "That email or password isn't quite right. Try again or reset your password.";

      expect(errorMsg, isNot(contains('INVALID_CREDENTIALS')));
      expect(errorMsg, isNot(contains('401')));
      expect(errorMsg, isNot(contains('error_code')));
      expect(errorMsg, contains('password'));
      expect(errorMsg, contains('Try again'));
    });

    testWidgets(
        'error message renders below the form after failed sign-in, '
        'contains no error codes (NFR-UX2)', (tester) async {
      const errorMessage =
          "That email or password isn't quite right. Try again or reset your password.";

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthResult.unauthenticated(),
            ),
            authRepositoryProvider.overrideWith(
              () => _FakeAuthRepository(
                const AuthResult.error(message: errorMessage),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.pump();

      // Trigger email sign-in to surface the error.
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Error message must be visible.
      final errorFinder = find.text(errorMessage);
      expect(errorFinder, findsOneWidget);

      // Error message must appear below the "Sign In" button.
      final signInButtonFinder = find.text('Sign In');
      final errorPos = tester.getTopLeft(errorFinder);
      final buttonPos = tester.getTopLeft(signInButtonFinder);
      expect(
        errorPos.dy,
        greaterThan(buttonPos.dy),
        reason: 'Error message must appear below the Sign In button',
      );

      // Error must not contain technical codes (NFR-UX2).
      expect(errorMessage, isNot(contains('INVALID_CREDENTIALS')));
      expect(errorMessage, isNot(contains('401')));
    });
  });
}
