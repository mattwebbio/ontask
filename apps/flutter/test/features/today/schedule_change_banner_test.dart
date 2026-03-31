import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/today/data/today_repository.dart';
import 'package:ontask/features/today/domain/overbooking_status.dart';
import 'package:ontask/features/today/domain/schedule_change.dart';
import 'package:ontask/features/today/presentation/schedule_change_provider.dart';
import 'package:ontask/features/today/presentation/widgets/schedule_change_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  ScheduleChanges stubChanges({bool hasMeaningfulChanges = true}) =>
      ScheduleChanges(
        hasMeaningfulChanges: hasMeaningfulChanges,
        changeCount: 2,
        changes: [
          const ScheduleChangeItem(
            taskId: 'a0000000-0000-4000-8000-000000000001',
            taskTitle: 'Morning review',
            changeType: ScheduleChangeType.moved,
            oldTime: null,
            newTime: null,
          ),
          const ScheduleChangeItem(
            taskId: 'a0000000-0000-4000-8000-000000000002',
            taskTitle: 'Team sync prep',
            changeType: ScheduleChangeType.removed,
            oldTime: null,
            newTime: null,
          ),
        ],
      );

  Widget buildBanner(ScheduleChanges changes) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: ScheduleChangeBanner(changes: changes),
        ),
      ),
    );
  }

  // ── ScheduleChangeBanner rendering ────────────────────────────────────────

  group('ScheduleChangeBanner', () {
    testWidgets('renders with banner message text', (tester) async {
      await tester.pumpWidget(buildBanner(stubChanges()));
      expect(
        find.text(AppStrings.scheduleChangeBannerMessage),
        findsOneWidget,
      );
    });

    testWidgets('dismiss button is present', (tester) async {
      await tester.pumpWidget(buildBanner(stubChanges()));
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    });

    testWidgets('"See what changed" button is present', (tester) async {
      await tester.pumpWidget(buildBanner(stubChanges()));
      expect(find.text(AppStrings.scheduleChangeSeeWhat), findsOneWidget);
    });

    testWidgets('tapping "See what changed" shows changes sheet', (tester) async {
      await tester.pumpWidget(buildBanner(stubChanges()));
      await tester.tap(find.text(AppStrings.scheduleChangeSeeWhat));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
    });

    testWidgets('changes sheet shows moved task title', (tester) async {
      await tester.pumpWidget(buildBanner(stubChanges()));
      await tester.tap(find.text(AppStrings.scheduleChangeSeeWhat));
      await tester.pumpAndSettle();
      expect(find.textContaining('Morning review'), findsOneWidget);
    });

    testWidgets('changes sheet shows removed task title', (tester) async {
      await tester.pumpWidget(buildBanner(stubChanges()));
      await tester.tap(find.text(AppStrings.scheduleChangeSeeWhat));
      await tester.pumpAndSettle();
      expect(find.textContaining('Team sync prep'), findsOneWidget);
    });

    testWidgets('tapping dismiss button sets banner visible to false', (tester) async {
      final container = ProviderContainer(
        overrides: [
          todayRepositoryProvider.overrideWithValue(
            _FakeTodayRepository(changes: stubChanges(hasMeaningfulChanges: true)),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(scheduleChangeBannerVisibleProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: Scaffold(body: ScheduleChangeBanner(changes: stubChanges())),
          ),
        ),
      );
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pump();
      expect(container.read(scheduleChangeBannerVisibleProvider).value, false);
      // Flush Riverpod dispose scheduler timers to avoid pending timer assertion.
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  // ── ScheduleChangeBannerAsync states ──────────────────────────────────────

  group('ScheduleChangeBannerAsync', () {
    testWidgets('renders SizedBox.shrink when banner not visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayRepositoryProvider.overrideWithValue(
              _FakeTodayRepository(
                changes: stubChanges(hasMeaningfulChanges: false),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const Scaffold(body: ScheduleChangeBannerAsync()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleChangeBanner), findsNothing);
    });

    testWidgets('renders ScheduleChangeBanner when visible and data loaded',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayRepositoryProvider.overrideWithValue(
              _FakeTodayRepository(
                changes: stubChanges(hasMeaningfulChanges: true),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const Scaffold(body: ScheduleChangeBannerAsync()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleChangeBanner), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink on loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayRepositoryProvider.overrideWithValue(
              _SlowTodayRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const Scaffold(body: ScheduleChangeBannerAsync()),
          ),
        ),
      );
      // Do not pumpAndSettle — keep loading state
      await tester.pump();
      expect(find.byType(ScheduleChangeBanner), findsNothing);
    });
  });

  // ── ScheduleChangeBannerVisible notifier ──────────────────────────────────

  group('ScheduleChangeBannerVisible notifier', () {
    test('dismiss() sets state to false', () async {
      final container = ProviderContainer(
        overrides: [
          todayRepositoryProvider.overrideWithValue(
            _FakeTodayRepository(changes: stubChanges(hasMeaningfulChanges: true)),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial state to resolve
      await container.read(scheduleChangeBannerVisibleProvider.future);
      expect(container.read(scheduleChangeBannerVisibleProvider).value, true);

      container.read(scheduleChangeBannerVisibleProvider.notifier).dismiss();
      expect(container.read(scheduleChangeBannerVisibleProvider).value, false);
    });

    test('initial state is true when hasMeaningfulChanges is true', () async {
      final container = ProviderContainer(
        overrides: [
          todayRepositoryProvider.overrideWithValue(
            _FakeTodayRepository(changes: stubChanges(hasMeaningfulChanges: true)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(scheduleChangeBannerVisibleProvider.future);
      expect(result, true);
    });
  });
}

// ── Fake today repositories ───────────────────────────────────────────────

class _FakeTodayRepository extends TodayRepository {
  final ScheduleChanges _changes;

  _FakeTodayRepository({required ScheduleChanges changes})
      : _changes = changes,
        super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleChanges> getScheduleChanges() async => _changes;

  @override
  Future<OverbookingStatus> getOverbookingStatus() async => OverbookingStatus(
        isOverbooked: false,
        severity: OverbookingSeverity.none,
        capacityPercent: 80,
        overbookedTasks: [],
      );
}

class _SlowTodayRepository extends TodayRepository {
  _SlowTodayRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleChanges> getScheduleChanges() {
    final completer = Completer<ScheduleChanges>();
    return completer.future; // never completes
  }
}
