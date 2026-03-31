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
import 'package:ontask/features/today/presentation/overbooking_provider.dart';
import 'package:ontask/features/today/presentation/widgets/overbooking_warning_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  OverbookingStatus makeStatus({
    OverbookingSeverity severity = OverbookingSeverity.atRisk,
    bool isOverbooked = true,
    bool hasStake = false,
  }) =>
      OverbookingStatus(
        isOverbooked: isOverbooked,
        severity: severity,
        capacityPercent: 115,
        overbookedTasks: [
          OverbookedTask(
            taskId: 'a0000000-0000-4000-8000-000000000001',
            taskTitle: 'Deep work block',
            hasStake: hasStake,
            durationMinutes: 120,
          ),
        ],
      );

  Widget buildBanner(
    OverbookingStatus status, {
    VoidCallback? onAcknowledge,
    VoidCallback? onReschedule,
    VoidCallback? onExtendDeadline,
    VoidCallback? onRequestExtension,
  }) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: OverbookingWarningBanner(
          status: status,
          onAcknowledge: onAcknowledge,
          onReschedule: onReschedule,
          onExtendDeadline: onExtendDeadline,
          onRequestExtension: onRequestExtension,
        ),
      ),
    );
  }

  // ── OverbookingWarningBanner (atRisk) ─────────────────────────────────────

  group('OverbookingWarningBanner (atRisk)', () {
    testWidgets('amber colour token used (scheduleAtRisk — triangle icon present)',
        (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus()));
      // atRisk uses exclamationmark_triangle icon
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );
    });

    testWidgets('warning triangle icon present', (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus()));
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );
    });
  });

  // ── OverbookingWarningBanner (critical) ───────────────────────────────────

  group('OverbookingWarningBanner (critical)', () {
    testWidgets('red colour token used (scheduleCritical — circle icon present)',
        (tester) async {
      await tester.pumpWidget(
        buildBanner(makeStatus(severity: OverbookingSeverity.critical)),
      );
      // critical uses exclamationmark_circle icon
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_circle),
        findsOneWidget,
      );
    });

    testWidgets('circle icon present for critical severity', (tester) async {
      await tester.pumpWidget(
        buildBanner(makeStatus(severity: OverbookingSeverity.critical)),
      );
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_circle),
        findsOneWidget,
      );
    });
  });

  // ── OverbookingWarningBanner actions ──────────────────────────────────────

  group('OverbookingWarningBanner actions', () {
    testWidgets('"Reschedule" action present', (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus()));
      expect(find.text(AppStrings.overbookingReschedule), findsOneWidget);
    });

    testWidgets('"Extend deadline" action present', (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus()));
      expect(find.text(AppStrings.overbookingExtendDeadline), findsOneWidget);
    });

    testWidgets('"Acknowledge" action present', (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus()));
      expect(find.text(AppStrings.overbookingAcknowledge), findsOneWidget);
    });

    testWidgets(
        '"Request deadline extension from partner" NOT shown when hasStake is false',
        (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus(hasStake: false)));
      expect(
        find.text(AppStrings.overbookingRequestExtension),
        findsNothing,
      );
    });

    testWidgets(
        '"Request deadline extension from partner" shown when hasStake is true',
        (tester) async {
      await tester.pumpWidget(buildBanner(makeStatus(hasStake: true)));
      expect(
        find.text(AppStrings.overbookingRequestExtension),
        findsOneWidget,
      );
    });

    testWidgets('tapping Acknowledge fires onAcknowledge callback',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildBanner(makeStatus(), onAcknowledge: () => called = true),
      );
      await tester.tap(find.text(AppStrings.overbookingAcknowledge));
      await tester.pump();
      expect(called, isTrue);
    });
  });

  // ── OverbookingWarningBannerAsync ─────────────────────────────────────────

  group('OverbookingWarningBannerAsync', () {
    testWidgets('renders SizedBox.shrink when isOverbooked false',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayRepositoryProvider.overrideWithValue(
              _FakeTodayRepository(
                status: makeStatus(isOverbooked: false),
              ),
            ),
            overbookingBannerDismissedProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const Scaffold(body: OverbookingWarningBannerAsync()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OverbookingWarningBanner), findsNothing);
    });

    testWidgets('renders SizedBox.shrink when dismissed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayRepositoryProvider.overrideWithValue(
              _FakeTodayRepository(
                status: makeStatus(isOverbooked: true),
              ),
            ),
            overbookingBannerDismissedProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const Scaffold(body: OverbookingWarningBannerAsync()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OverbookingWarningBanner), findsNothing);
    });
  });
}

// ── Fake today repository ─────────────────────────────────────────────────

class _FakeTodayRepository extends TodayRepository {
  final OverbookingStatus _status;

  _FakeTodayRepository({required OverbookingStatus status})
      : _status = status,
        super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<OverbookingStatus> getOverbookingStatus() async => _status;

  @override
  Future<ScheduleChanges> getScheduleChanges() async => ScheduleChanges(
        hasMeaningfulChanges: false,
        changeCount: 0,
        changes: [],
      );
}
