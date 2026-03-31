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
import 'package:ontask/features/tasks/domain/recurrence_rule.dart';
import 'package:ontask/features/tasks/domain/task.dart';
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

  // ── RecurrenceRule enum ────────────────────────────────────────────────

  group('RecurrenceRule enum', () {
    test('fromJson/toJson round-trip for all values', () {
      for (final rule in RecurrenceRule.values) {
        final json = rule.toJson();
        final parsed = RecurrenceRule.fromJson(json);
        expect(parsed, equals(rule));
      }
    });

    test('fromJson returns null for null input', () {
      expect(RecurrenceRule.fromJson(null), isNull);
    });

    test('fromJson returns null for invalid input', () {
      expect(RecurrenceRule.fromJson('biweekly'), isNull);
    });

    test('toJson returns name string', () {
      expect(RecurrenceRule.daily.toJson(), 'daily');
      expect(RecurrenceRule.weekly.toJson(), 'weekly');
      expect(RecurrenceRule.monthly.toJson(), 'monthly');
      expect(RecurrenceRule.custom.toJson(), 'custom');
    });
  });

  // ── AddTabSheet: recurrence picker ─────────────────────────────────────

  group('AddTabSheet — recurrence picker', () {
    testWidgets('shows recurrence picker label', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll to recurrence picker
      await tester.dragUntilVisible(
        find.text(AppStrings.taskRecurrenceLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      expect(find.text(AppStrings.taskRecurrenceLabel), findsOneWidget);
    });

    testWidgets('recurrence picker shows options when tapped', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll to recurrence picker
      await tester.dragUntilVisible(
        find.text(AppStrings.taskRecurrenceLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskRecurrenceLabel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskRecurrenceDaily), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceWeekly), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceMonthly), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceCustom), findsOneWidget);
    });

    testWidgets('selecting weekly shows day-of-week picker', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll to and open recurrence picker
      await tester.dragUntilVisible(
        find.text(AppStrings.taskRecurrenceLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskRecurrenceLabel));
      await tester.pumpAndSettle();

      // Select weekly
      await tester.tap(find.text(AppStrings.taskRecurrenceWeekly));
      await tester.pumpAndSettle();

      // Verify day picker appears
      expect(find.text(AppStrings.taskRecurrenceWeeklyDaysLabel), findsOneWidget);
      expect(find.text(AppStrings.taskDayMonday), findsOneWidget);
      expect(find.text(AppStrings.taskDaySunday), findsOneWidget);
    });

    testWidgets('selecting custom shows interval picker', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll to and open recurrence picker
      await tester.dragUntilVisible(
        find.text(AppStrings.taskRecurrenceLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskRecurrenceLabel));
      await tester.pumpAndSettle();

      // Select custom
      await tester.tap(find.text(AppStrings.taskRecurrenceCustom));
      await tester.pumpAndSettle();

      // Verify custom interval picker appears
      expect(find.text(AppStrings.taskRecurrenceCustomDaysLabel), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsOneWidget);
    });

    testWidgets('selecting daily updates label', (tester) async {
      await tester.pumpWidget(buildAddTabSheet());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll to and open recurrence picker
      await tester.dragUntilVisible(
        find.text(AppStrings.taskRecurrenceLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.text(AppStrings.taskRecurrenceLabel));
      await tester.pumpAndSettle();

      // Select daily
      await tester.tap(find.text(AppStrings.taskRecurrenceDaily));
      await tester.pumpAndSettle();

      // Verify label updated
      expect(
        find.text(
            '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceDaily}'),
        findsOneWidget,
      );
    });
  });

  // ── TaskEditInline: recurrence picker ──────────────────────────────────

  group('TaskEditInline — recurrence picker', () {
    testWidgets('renders recurrence picker', (tester) async {
      await tester.pumpWidget(buildTaskEditInline(baseTask));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text(AppStrings.taskRecurrenceLabel),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      expect(find.text(AppStrings.taskRecurrenceLabel), findsOneWidget);
    });

    testWidgets('shows edit scope choice for recurring task', (tester) async {
      final recurringTask = baseTask.copyWith(
        recurrenceRule: RecurrenceRule.daily,
      );
      await tester.pumpWidget(buildTaskEditInline(recurringTask));
      await tester.pumpAndSettle();

      // Change the title to trigger edit
      final titleField = find.byType(CupertinoTextField).first;
      await tester.enterText(titleField, 'Updated title');
      await tester.pumpAndSettle();

      // Verify edit scope choice is shown
      expect(find.text(AppStrings.taskRecurrenceEditChoiceTitle), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceEditThisInstance), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceEditAllFuture), findsOneWidget);
    });

    testWidgets('displays current recurrence value on task', (tester) async {
      final dailyTask = baseTask.copyWith(
        recurrenceRule: RecurrenceRule.daily,
      );
      await tester.pumpWidget(buildTaskEditInline(dailyTask));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.textContaining(AppStrings.taskRecurrenceDaily),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      expect(
        find.text(
            '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceDaily}'),
        findsOneWidget,
      );
    });
  });

  // ── TaskRow: recurrence badge ──────────────────────────────────────────

  group('TaskRow — recurrence badge', () {
    testWidgets('shows repeat badge when recurrenceRule is set',
        (tester) async {
      final dailyTask = baseTask.copyWith(
        recurrenceRule: RecurrenceRule.daily,
      );
      await tester.pumpWidget(buildTaskRow(dailyTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.repeat), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceDaily), findsOneWidget);
    });

    testWidgets('shows weekly label for weekly recurrence', (tester) async {
      final weeklyTask = baseTask.copyWith(
        recurrenceRule: RecurrenceRule.weekly,
      );
      await tester.pumpWidget(buildTaskRow(weeklyTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.repeat), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceWeekly), findsOneWidget);
    });

    testWidgets('shows monthly label for monthly recurrence', (tester) async {
      final monthlyTask = baseTask.copyWith(
        recurrenceRule: RecurrenceRule.monthly,
      );
      await tester.pumpWidget(buildTaskRow(monthlyTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.repeat), findsOneWidget);
      expect(find.text(AppStrings.taskRecurrenceMonthly), findsOneWidget);
    });

    testWidgets('shows custom interval label for custom recurrence',
        (tester) async {
      final customTask = baseTask.copyWith(
        recurrenceRule: RecurrenceRule.custom,
        recurrenceInterval: 5,
      );
      await tester.pumpWidget(buildTaskRow(customTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.repeat), findsOneWidget);
      expect(find.text('Every 5 days'), findsOneWidget);
    });

    testWidgets('hides repeat badge when recurrenceRule is null',
        (tester) async {
      await tester.pumpWidget(buildTaskRow(baseTask));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.repeat), findsNothing);
    });
  });
}
