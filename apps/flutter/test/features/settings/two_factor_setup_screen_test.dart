import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/settings/data/settings_repository.dart';
import 'package:ontask/features/settings/domain/two_factor_setup_data.dart';
import 'package:ontask/features/settings/presentation/two_factor_setup_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSettingsRepository extends Mock implements SettingsRepository {}
class MockApiClient extends Mock implements ApiClient {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _stubSetupData = TwoFactorSetupData(
  secret: 'STUBSECRETBASE32',
  otpauthUri:
      'otpauth://totp/OnTask:test@example.com?secret=STUBSECRETBASE32&issuer=OnTask',
  backupCodes: [
    'STUB-CODE-1',
    'STUB-CODE-2',
    'STUB-CODE-3',
    'STUB-CODE-4',
    'STUB-CODE-5',
    'STUB-CODE-6',
    'STUB-CODE-7',
    'STUB-CODE-8',
    'STUB-CODE-9',
    'STUB-CODE-10',
  ],
);

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderScope _buildScreenWithRepo(MockSettingsRepository repo) {
  when(() => repo.setup2FA()).thenAnswer((_) async => _stubSetupData);
  when(() => repo.confirm2FA(any())).thenAnswer((_) async => true);

  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
      twoFactorSetupProvider.overrideWith((ref) async => _stubSetupData),
    ],
    child: MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: const TwoFactorSetupScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue('');
  });

  group('TwoFactorSetupScreen — content rendering', () {
    testWidgets('renders QR code widget when setup data is loaded',
        (tester) async {
      final repo = MockSettingsRepository();
      await tester.pumpWidget(_buildScreenWithRepo(repo));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('displays the TOTP secret for manual entry', (tester) async {
      final repo = MockSettingsRepository();
      await tester.pumpWidget(_buildScreenWithRepo(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('STUBSECRETBASE32'), findsWidgets);
    });

    testWidgets('displays backup codes', (tester) async {
      final repo = MockSettingsRepository();
      await tester.pumpWidget(_buildScreenWithRepo(repo));
      await tester.pumpAndSettle();

      // Scroll down to see backup codes section.
      await tester.dragUntilVisible(
        find.text('STUB-CODE-1'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUB-CODE-1'), findsOneWidget);
    });

    testWidgets('shows confirm button (scrolled into view)', (tester) async {
      final repo = MockSettingsRepository();
      await tester.pumpWidget(_buildScreenWithRepo(repo));
      await tester.pumpAndSettle();

      // Scroll to confirm button.
      await tester.dragUntilVisible(
        find.text(AppStrings.twoFactorConfirmButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.twoFactorConfirmButton), findsOneWidget);
    });
  });

  group('TwoFactorSetupScreen — confirmation step', () {
    testWidgets('calls confirm2FA() when user submits a code', (tester) async {
      final repo = MockSettingsRepository();
      await tester.pumpWidget(_buildScreenWithRepo(repo));
      await tester.pumpAndSettle();

      // Scroll to the code entry field.
      await tester.dragUntilVisible(
        find.byType(CupertinoTextField).first,
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoTextField).first, '123456');
      await tester.pumpAndSettle();

      // Scroll to confirm button.
      await tester.dragUntilVisible(
        find.text(AppStrings.twoFactorConfirmButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.twoFactorConfirmButton),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(() => repo.confirm2FA('123456')).called(1);
    });

    testWidgets('shows success state when code is valid', (tester) async {
      final repo = MockSettingsRepository();
      await tester.pumpWidget(_buildScreenWithRepo(repo));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byType(CupertinoTextField).first,
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoTextField).first, '123456');
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text(AppStrings.twoFactorConfirmButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.twoFactorConfirmButton),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.twoFactorSetupSuccess), findsOneWidget);
    });

    testWidgets('shows error message when code is invalid', (tester) async {
      final repo = MockSettingsRepository();
      when(() => repo.setup2FA()).thenAnswer((_) async => _stubSetupData);
      when(() => repo.confirm2FA(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
            twoFactorSetupProvider.overrideWith((ref) async => _stubSetupData),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const TwoFactorSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byType(CupertinoTextField).first,
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoTextField).first, '999999');
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text(AppStrings.twoFactorConfirmButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.twoFactorConfirmButton),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.twoFactorSetupError), findsOneWidget);
    });
  });
}
