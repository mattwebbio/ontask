import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/shell/presentation/add_tab_sheet.dart';
import 'package:ontask/features/tasks/domain/energy_requirement.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/domain/task_priority.dart';
import 'package:ontask/features/tasks/domain/time_window.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_edit_inline.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget buildAddTabSheet() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open'),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddTabSheet(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTaskEditInline(Task task) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskEditInline(task: task, onDone: () {}),
          ),
        ),
      ),
    );
  }

  Widget buildTaskRow(Task task) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: TaskRow(task: task),
      ),
    );
  }

  final baseTask = Task(
    id: 'task-1',
    title: 'Test task',
    position: 0,
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  // ── AddTabSheet: scheduling hint pickers ─────────────────────────────────

  group('AddTabSheet — scheduling hint pickers', () {
    // Helper: open the sheet and switch to Form mode
    // (Sheet defaults to Quick Capture mode since Story 4.1)
    Future<void> openSheetInFormMode(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.addTaskModeForm));
      await tester.pump();
    }

    testWidgets('shows time window picker label', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      expect(find.text(AppStrings.taskTimeWindowLabel), findsOneWidget);
    });

    testWidgets('shows energy requirement picker label', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      expect(find.text(AppStrings.taskEnergyLabel), findsOneWidget);
    });

    testWidgets('shows priority picker label', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      expect(find.text(AppStrings.taskPriorityLabel), findsOneWidget);
    });

    testWidgets('time window picker shows options when tapped',
        (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      // Tap the time window picker row
      await tester.tap(find.text(AppStrings.taskTimeWindowLabel));
      await tester.pumpAndSettle();

      // Verify action sheet options
      expect(find.text(AppStrings.taskTimeWindowMorning), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowAfternoon), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowEvening), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowCustom), findsOneWidget);
    });

    testWidgets('energy requirement picker shows options when tapped',
        (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      // Scroll to energy picker and tap
      await tester.dragUntilVisible(
        find.text(AppStrings.taskEnergyLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskEnergyLabel));
      await tester.pumpAndSettle();

      // Verify action sheet options
      expect(find.text(AppStrings.taskEnergyHighFocus), findsOneWidget);
      expect(find.text(AppStrings.taskEnergyLowEnergy), findsOneWidget);
      expect(find.text(AppStrings.taskEnergyFlexible), findsOneWidget);
    });

    testWidgets('priority picker shows options when tapped', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      // Scroll to priority picker and tap
      await tester.dragUntilVisible(
        find.text(AppStrings.taskPriorityLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskPriorityLabel));
      await tester.pumpAndSettle();

      // Verify action sheet options
      expect(find.text(AppStrings.taskPriorityNormal), findsOneWidget);
      expect(find.text(AppStrings.taskPriorityHigh), findsOneWidget);
      expect(find.text(AppStrings.taskPriorityCritical), findsOneWidget);
    });

    testWidgets('selecting time window updates label', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      // Open time window picker
      await tester.tap(find.text(AppStrings.taskTimeWindowLabel));
      await tester.pumpAndSettle();

      // Select morning
      await tester.tap(find.text(AppStrings.taskTimeWindowMorning));
      await tester.pumpAndSettle();

      // Verify label updated
      expect(
        find.text(
            '${AppStrings.taskTimeWindowLabel}: ${AppStrings.taskTimeWindowMorning}'),
        findsOneWidget,
      );
    });

    testWidgets('selecting custom time window shows time range picker',
        (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await openSheetInFormMode(tester);

      // Open time window picker
      await tester.tap(find.text(AppStrings.taskTimeWindowLabel));
      await tester.pumpAndSettle();

      // Select custom
      await tester.tap(find.text(AppStrings.taskTimeWindowCustom));
      await tester.pumpAndSettle();

      // Verify custom time range picker appears with start/end labels
      expect(find.text(AppStrings.taskTimeWindowCustomStart), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowCustomEnd), findsOneWidget);
    });
  });

  // ── TaskEditInline: scheduling hint pickers ──────────────────────────────

  group('TaskEditInline — scheduling hint pickers', () {
    testWidgets('renders time window picker', (tester) async {
      await tester.pumpWidget(buildTaskEditInline(baseTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskTimeWindowLabel), findsOneWidget);
    });

    testWidgets('renders energy requirement picker', (tester) async {
      await tester.pumpWidget(buildTaskEditInline(baseTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskEnergyLabel), findsOneWidget);
    });

    testWidgets('renders priority picker', (tester) async {
      await tester.pumpWidget(buildTaskEditInline(baseTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskPriorityLabel), findsOneWidget);
    });

    testWidgets('time window picker shows action sheet when tapped',
        (tester) async {
      await tester.pumpWidget(buildTaskEditInline(baseTask));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text(AppStrings.taskTimeWindowLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskTimeWindowLabel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskTimeWindowMorning), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowAfternoon), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowEvening), findsOneWidget);
      expect(find.text(AppStrings.taskTimeWindowCustom), findsOneWidget);
    });

    testWidgets('displays current time window value on task', (tester) async {
      final taskWithTimeWindow = baseTask.copyWith(
        timeWindow: TimeWindow.morning,
      );
      await tester.pumpWidget(buildTaskEditInline(taskWithTimeWindow));
      await tester.pumpAndSettle();

      expect(
        find.text(
            '${AppStrings.taskTimeWindowLabel}: ${AppStrings.taskTimeWindowMorning}'),
        findsOneWidget,
      );
    });

    testWidgets('displays current energy requirement value on task',
        (tester) async {
      final taskWithEnergy = baseTask.copyWith(
        energyRequirement: EnergyRequirement.highFocus,
      );
      await tester.pumpWidget(buildTaskEditInline(taskWithEnergy));
      await tester.pumpAndSettle();

      expect(
        find.text(
            '${AppStrings.taskEnergyLabel}: ${AppStrings.taskEnergyHighFocus}'),
        findsOneWidget,
      );
    });

    testWidgets('displays current priority value on task', (tester) async {
      final taskWithPriority = baseTask.copyWith(
        priority: TaskPriority.critical,
      );
      await tester.pumpWidget(buildTaskEditInline(taskWithPriority));
      await tester.pumpAndSettle();

      expect(
        find.text(
            '${AppStrings.taskPriorityLabel}: ${AppStrings.taskPriorityCritical}'),
        findsOneWidget,
      );
    });
  });

  // ── TaskRow: scheduling hint badges ──────────────────────────────────────

  group('TaskRow — scheduling hint badges', () {
    testWidgets('shows priority badge for critical task', (tester) async {
      final criticalTask = baseTask.copyWith(priority: TaskPriority.critical);
      await tester.pumpWidget(buildTaskRow(criticalTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskPriorityCritical), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.flag_fill), findsOneWidget);
    });

    testWidgets('shows priority badge for high priority task', (tester) async {
      final highTask = baseTask.copyWith(priority: TaskPriority.high);
      await tester.pumpWidget(buildTaskRow(highTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskPriorityHigh), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.flag_fill), findsOneWidget);
    });

    testWidgets('hides priority badge for normal priority task',
        (tester) async {
      final normalTask = baseTask.copyWith(priority: TaskPriority.normal);
      await tester.pumpWidget(buildTaskRow(normalTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.flag_fill), findsNothing);
    });

    testWidgets('shows time window badge when set', (tester) async {
      final morningTask = baseTask.copyWith(timeWindow: TimeWindow.morning);
      await tester.pumpWidget(buildTaskRow(morningTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskTimeWindowMorning), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.clock), findsOneWidget);
    });

    testWidgets('shows energy badge when set', (tester) async {
      final energyTask =
          baseTask.copyWith(energyRequirement: EnergyRequirement.highFocus);
      await tester.pumpWidget(buildTaskRow(energyTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskEnergyHighFocus), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.bolt), findsOneWidget);
    });

    testWidgets('hides badges when no scheduling hints set', (tester) async {
      await tester.pumpWidget(buildTaskRow(baseTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.flag_fill), findsNothing);
      expect(find.byIcon(CupertinoIcons.clock), findsNothing);
      expect(find.byIcon(CupertinoIcons.bolt), findsNothing);
    });

    testWidgets('shows custom time window with start/end times',
        (tester) async {
      final customTask = baseTask.copyWith(
        timeWindow: TimeWindow.custom,
        timeWindowStart: '09:00',
        timeWindowEnd: '11:30',
      );
      await tester.pumpWidget(buildTaskRow(customTask));
      await tester.pumpAndSettle();

      expect(find.textContaining('09:00'), findsOneWidget);
      expect(find.textContaining('11:30'), findsOneWidget);
    });
  });
}
