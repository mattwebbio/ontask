import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/settings/data/settings_repository.dart';
import 'package:ontask/features/settings/domain/session_model.dart';
import 'package:ontask/features/settings/presentation/sessions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSettingsRepository extends Mock implements SettingsRepository {}
class MockApiClient extends Mock implements ApiClient {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _currentSession = SessionModel(
  sessionId: 'sess_current',
  deviceName: 'iPhone 16 Pro',
  location: 'London, UK',
  lastActiveAt: DateTime.now(),
  isCurrentDevice: true,
);

final _otherSession = SessionModel(
  sessionId: 'sess_other',
  deviceName: 'iPad Pro',
  location: 'Berlin, DE',
  lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
  isCurrentDevice: false,
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> pumpSessionsScreen(
  WidgetTester tester, {
  required MockSettingsRepository mockRepo,
  List<SessionModel>? sessions,
}) async {
  final sessionList = sessions ?? [_currentSession, _otherSession];

  when(() => mockRepo.getSessions()).thenAnswer((_) async => sessionList);
  when(() => mockRepo.deleteSession(any())).thenAnswer((_) async {});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepo),
        activeSessionsProvider.overrideWith((ref) async {
          final repo = ref.watch(settingsRepositoryProvider);
          return repo.getSessions();
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const SessionsScreen(),
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
    registerFallbackValue('');
  });

  group('SessionsScreen — session list rendering', () {
    testWidgets('renders device names for all sessions', (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      expect(find.text('iPhone 16 Pro'), findsOneWidget);
      expect(find.text('iPad Pro'), findsOneWidget);
    });

    testWidgets('renders location and last-active info', (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      expect(find.textContaining('London, UK'), findsOneWidget);
      expect(find.textContaining('Berlin, DE'), findsOneWidget);
    });

    testWidgets('current session shows "This device" badge', (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      expect(find.text(AppStrings.sessionsCurrentDevice), findsOneWidget);
    });

    testWidgets('non-current session shows "Sign out this device" button',
        (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      expect(find.text(AppStrings.sessionsSignOut), findsOneWidget);
    });

    testWidgets('current session does NOT show sign-out button', (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      // Only one "Sign out this device" — for the non-current session.
      expect(find.text(AppStrings.sessionsSignOut), findsOneWidget);
    });
  });

  group('SessionsScreen — sign-out flow', () {
    testWidgets('tapping sign-out shows confirmation dialog', (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      await tester.tap(find.text(AppStrings.sessionsSignOut));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.sessionsSignOutConfirmTitle),
        findsOneWidget,
      );
    });

    testWidgets('confirmation dialog shows Cancel and Sign out actions',
        (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      await tester.tap(find.text(AppStrings.sessionsSignOut));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sessionsSignOutCancel), findsOneWidget);
      expect(find.text(AppStrings.sessionsSignOutConfirm), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses dialog without calling deleteSession',
        (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      await tester.tap(find.text(AppStrings.sessionsSignOut));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.sessionsSignOutCancel));
      await tester.pumpAndSettle();

      verifyNever(() => repo.deleteSession(any()));
      expect(find.text(AppStrings.sessionsSignOutConfirmTitle), findsNothing);
    });

    testWidgets('tapping Sign out calls DELETE on repository', (tester) async {
      final repo = MockSettingsRepository();
      await pumpSessionsScreen(tester, mockRepo: repo);

      await tester.tap(find.text(AppStrings.sessionsSignOut));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.sessionsSignOutConfirm));
      await tester.pumpAndSettle();

      verify(() => repo.deleteSession('sess_other')).called(1);
    });
  });

  group('SessionsScreen — error state', () {
    testWidgets('shows plain-language error when sessions load fails',
        (tester) async {
      final repo = MockSettingsRepository();
      when(() => repo.getSessions()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
            activeSessionsProvider.overrideWith(
              (ref) => Future.error(Exception('Network error')),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const SessionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.sessionsSignOutErrorMessage),
        findsOneWidget,
      );
    });
  });
}
