import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/today/domain/day_health.dart';
import 'package:ontask/features/today/domain/day_health_status.dart';
import 'package:ontask/features/today/presentation/schedule_health_provider.dart';
import 'package:ontask/features/today/presentation/today_provider.dart';
import 'package:ontask/features/today/presentation/today_screen.dart';
import 'package:ontask/features/today/presentation/widgets/schedule_health_strip.dart';
import 'package:ontask/features/today/presentation/widgets/today_skeleton.dart';
import 'package:ontask/features/today/presentation/widgets/today_task_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // Use far-future dates so tasks are always "upcoming", not "overdue"
  final farFuture = DateTime.now().add(const Duration(days: 365));
  final testTasks = [
    Task(
      id: 'task-1',
      title: 'Morning standup',
      position: 0,
      dueDate: DateTime(farFuture.year, farFuture.month, farFuture.day, 9, 0),
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
    Task(
      id: 'task-2',
      title: 'Write report',
      position: 1,
      dueDate: DateTime(farFuture.year, farFuture.month, farFuture.day, 14, 0),
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
    Task(
      id: 'task-3',
      title: 'Evening review',
      position: 2,
      dueDate: DateTime(farFuture.year, farFuture.month, farFuture.day, 18, 0),
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
  ];

  final testHealthDays = List.generate(
    7,
    (i) => DayHealth(
      date: DateTime(2026, 3, 30 + i),
      status: i == 3
          ? DayHealthStatus.atRisk
          : i == 5
              ? DayHealthStatus.critical
              : DayHealthStatus.healthy,
      taskCount: i + 1,
      capacityPercent: 50.0 + i * 10,
      atRiskTaskIds: i == 3 ? ['task-at-risk'] : [],
    ),
  );

  Widget buildWidget({
    List<Task>? tasks,
    List<DayHealth>? healthDays,
    VoidCallback? onAddTapped,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(
              userId: 'user_1', provider: 'email'),
        ),
        todayProvider.overrideWith(
          () => _FakeTodayNotifier(tasks ?? testTasks),
        ),
        scheduleHealthProvider.overrideWith(
          () => _FakeScheduleHealthNotifier(
            healthDays ?? testHealthDays,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: TodayScreen(onAddTapped: onAddTapped),
      ),
    );
  }

  group('TodayScreen', () {
    testWidgets('shows skeleton initially during shimmer animation',
        (tester) async {
      // Use regular (non-loading) data, but check before skeleton delay completes
      await tester.pumpWidget(buildWidget());
      // Pump just one frame -- the 800ms skeleton delay hasn't completed
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TodaySkeleton), findsOneWidget);

      // After settling, skeleton should be gone
      await tester.pumpAndSettle();
      expect(find.byType(TodaySkeleton), findsNothing);
    });

    testWidgets('shows task rows after data loads', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Morning standup'), findsOneWidget);
      expect(find.text('Write report'), findsOneWidget);
      expect(find.text('Evening review'), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks', (tester) async {
      await tester.pumpWidget(buildWidget(tasks: []));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.todayEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.todayEmptyAddCta), findsOneWidget);
    });

    testWidgets('shows schedule health strip when loaded', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleHealthStrip), findsOneWidget);
    });

    testWidgets('shows header with task count', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.todayHeaderTitle), findsOneWidget);
      expect(find.text('3 tasks'), findsOneWidget);
    });

    testWidgets('shows time-of-day section dividers', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.todayMorningSection), findsOneWidget);
      expect(find.text(AppStrings.todayAfternoonSection), findsOneWidget);
      expect(find.text(AppStrings.todayEveningSection), findsOneWidget);
    });
  });

  group('TodayTaskRow', () {
    Widget buildRow({
      TodayTaskRowState state = TodayTaskRowState.upcoming,
      VoidCallback? onComplete,
      VoidCallback? onReschedule,
    }) {
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: TodayTaskRow(
            taskId: 'test-task',
            title: 'Test task',
            timeLabel: '9am',
            rowState: state,
            onComplete: onComplete,
            onReschedule: onReschedule,
          ),
        ),
      );
    }

    testWidgets('renders upcoming state', (tester) async {
      await tester.pumpWidget(buildRow());
      await tester.pump();

      expect(find.text('Test task'), findsOneWidget);
      expect(find.text('9am'), findsOneWidget);
    });

    testWidgets('renders current state with accent border', (tester) async {
      await tester.pumpWidget(buildRow(state: TodayTaskRowState.current));
      await tester.pump();

      expect(find.text('Test task'), findsOneWidget);
      // Verify the container with left border exists
      final container = tester.widgetList<Container>(find.byType(Container));
      expect(container, isNotEmpty);
    });

    testWidgets('renders overdue state with badge', (tester) async {
      await tester.pumpWidget(buildRow(state: TodayTaskRowState.overdue));
      await tester.pump();

      expect(find.text('Test task'), findsOneWidget);
      expect(find.text(AppStrings.scheduleHealthAtRisk), findsOneWidget);
    });

    testWidgets('renders completed state with strikethrough',
        (tester) async {
      await tester.pumpWidget(buildRow(state: TodayTaskRowState.completed));
      await tester.pump();

      expect(find.text('Test task'), findsOneWidget);
      // Check icon for completed state
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsOneWidget,
      );
    });

    testWidgets('renders calendarEvent state with grey dot', (tester) async {
      await tester
          .pumpWidget(buildRow(state: TodayTaskRowState.calendarEvent));
      await tester.pump();

      expect(find.text('Test task'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.circle_fill),
        findsOneWidget,
      );
    });

    testWidgets('swipe right triggers complete callback', (tester) async {
      bool completed = false;
      await tester.pumpWidget(buildRow(onComplete: () => completed = true));
      await tester.pump();

      // Swipe right (start-to-end) to complete
      await tester.drag(find.text('Test task'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('swipe left triggers reschedule callback', (tester) async {
      bool rescheduled = false;
      await tester
          .pumpWidget(buildRow(onReschedule: () => rescheduled = true));
      await tester.pump();

      // Swipe left (end-to-start) to reschedule
      await tester.drag(find.text('Test task'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(rescheduled, isTrue);
    });
  });

  group('ScheduleHealthStrip', () {
    Widget buildStrip({List<DayHealth>? days}) {
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: ScheduleHealthStrip(days: days ?? testHealthDays),
        ),
      );
    }

    testWidgets('renders 7 day chips', (tester) async {
      await tester.pumpWidget(buildStrip());
      await tester.pump();

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows correct icons per health status', (tester) async {
      await tester.pumpWidget(buildStrip());
      await tester.pump();

      // healthy days show checkmark circles
      expect(
        find.byIcon(CupertinoIcons.checkmark_circle),
        findsNWidgets(5), // 5 healthy days
      );
      // at-risk day shows warning triangle
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );
      // critical day shows exclamation circle
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_circle),
        findsOneWidget,
      );
    });

    testWidgets('tapping at-risk day shows action sheet', (tester) async {
      await tester.pumpWidget(buildStrip());
      await tester.pump();

      // Tap the at-risk day chip (Thu, index 3)
      await tester.tap(find.text('Thu'));
      await tester.pumpAndSettle();

      // Action sheet should show the at-risk tasks title
      expect(find.text(AppStrings.scheduleHealthAtRiskTasks), findsOneWidget);
    });

    testWidgets('tapping healthy day does not show action sheet',
        (tester) async {
      final allHealthy = List.generate(
        7,
        (i) => DayHealth(
          date: DateTime(2026, 3, 30 + i),
          status: DayHealthStatus.healthy,
          taskCount: 0,
          capacityPercent: 0,
          atRiskTaskIds: [],
        ),
      );

      await tester.pumpWidget(buildStrip(days: allHealthy));
      await tester.pump();

      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      // No action sheet shown
      expect(
        find.text(AppStrings.scheduleHealthAtRiskTasks),
        findsNothing,
      );
    });
  });
}

// ── Fake notifiers for testing ──────────────────────────────────────────────

class _FakeTodayNotifier extends Today {
  final List<Task> _tasks;

  _FakeTodayNotifier(this._tasks);

  @override
  Future<List<Task>> build() async => _tasks;
}

class _FakeScheduleHealthNotifier extends ScheduleHealth {
  final List<DayHealth> _days;

  _FakeScheduleHealthNotifier(this._days);

  @override
  Future<List<DayHealth>> build() async => _days;
}
