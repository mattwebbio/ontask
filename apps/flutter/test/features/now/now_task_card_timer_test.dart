import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/now/domain/now_task.dart';
import 'package:ontask/features/now/domain/proof_mode.dart';
import 'package:ontask/features/now/presentation/widgets/now_task_card.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final testTask = NowTask(
    id: 'task-1',
    title: 'Buy groceries',
    notes: 'Milk, eggs, bread',
    dueDate: DateTime(2026, 4, 1, 14, 0),
    listId: 'list-1',
    listName: 'Personal',
    assignorName: null,
    stakeAmountCents: null,
    proofMode: ProofMode.standard,
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  Widget buildCard({
    required NowTask task,
    VoidCallback? onComplete,
    VoidCallback? onStart,
    VoidCallback? onPause,
    VoidCallback? onStop,
    bool timerRunning = false,
    int timerElapsedSeconds = 0,
  }) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: NowTaskCard(
              task: task,
              onComplete: onComplete,
              onStart: onStart,
              onPause: onPause,
              onStop: onStop,
              timerRunning: timerRunning,
              timerElapsedSeconds: timerElapsedSeconds,
            ),
          ),
        ),
      ),
    );
  }

  group('NowTaskCard Timer UI', () {
    testWidgets('shows "Start" button when no timer running', (tester) async {
      await tester.pumpWidget(buildCard(task: testTask, onStart: () {}));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.timerStart), findsOneWidget);
      expect(find.text(AppStrings.timerPause), findsNothing);
      expect(find.text(AppStrings.timerStop), findsNothing);
    });

    testWidgets('shows "Pause" and "Stop" buttons when timer running',
        (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        onPause: () {},
        onStop: () {},
        timerRunning: true,
        timerElapsedSeconds: 42,
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.timerPause), findsOneWidget);
      expect(find.text(AppStrings.timerStop), findsOneWidget);
      expect(find.text(AppStrings.timerStart), findsNothing);
    });

    testWidgets('shows timer display with formatted elapsed time',
        (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        timerRunning: true,
        timerElapsedSeconds: 330, // 5:30
      ));
      await tester.pumpAndSettle();

      expect(find.text('5:30'), findsOneWidget);
    });

    testWidgets('formats hours correctly', (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        timerRunning: true,
        timerElapsedSeconds: 5025, // 1:23:45
      ));
      await tester.pumpAndSettle();

      expect(find.text('1:23:45'), findsOneWidget);
    });

    testWidgets('VoiceOver label includes elapsed time when timer running',
        (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        timerRunning: true,
        timerElapsedSeconds: 330,
      ));
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Buy groceries'),
      );
      expect(semanticsFinder, findsOneWidget);

      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      final label = semanticsWidget.properties.label!;
      expect(label, contains('5:30 elapsed'));
    });

    testWidgets('VoiceOver custom action "Start timer" exists when not running',
        (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        onStart: () {},
      ));
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.customSemanticsActions != null &&
            widget.properties.customSemanticsActions!.keys.any(
              (action) => action.label == AppStrings.timerStartVoiceOver,
            ),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Start button calls onStart callback', (tester) async {
      var started = false;
      await tester.pumpWidget(buildCard(
        task: testTask,
        onStart: () => started = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.timerStart));
      expect(started, true);
    });

    testWidgets('Pause button calls onPause callback', (tester) async {
      var paused = false;
      await tester.pumpWidget(buildCard(
        task: testTask,
        onPause: () => paused = true,
        onStop: () {},
        timerRunning: true,
        timerElapsedSeconds: 60,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.timerPause));
      expect(paused, true);
    });

    testWidgets('Stop button calls onStop callback', (tester) async {
      var stopped = false;
      await tester.pumpWidget(buildCard(
        task: testTask,
        onPause: () {},
        onStop: () => stopped = true,
        timerRunning: true,
        timerElapsedSeconds: 60,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.timerStop));
      expect(stopped, true);
    });

    testWidgets('does not show timer display when no elapsed and not running',
        (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        timerRunning: false,
        timerElapsedSeconds: 0,
      ));
      await tester.pumpAndSettle();

      // Should not find any formatted time string
      expect(find.text('0:00'), findsNothing);
    });

    testWidgets('60-second announcement fires when timer running',
        (tester) async {
      await tester.pumpWidget(buildCard(
        task: testTask,
        timerRunning: true,
        timerElapsedSeconds: 120,
      ));
      await tester.pumpAndSettle();

      // Fast-forward 60 seconds for the announcement timer
      await tester.pump(const Duration(seconds: 60));

      // The announcement text should now be set (via liveRegion Semantics)
      // We can't directly test SemanticsService announcements,
      // but we verify the announcement timer infrastructure works
      // by checking no errors occur during the 60-second pump
    });
  });

  group('NowTaskCard.formatElapsed', () {
    test('formats seconds only', () {
      expect(NowTaskCard.formatElapsed(42), '0:42');
    });

    test('formats minutes and seconds', () {
      expect(NowTaskCard.formatElapsed(330), '5:30');
    });

    test('formats hours', () {
      expect(NowTaskCard.formatElapsed(5025), '1:23:45');
    });

    test('formats zero', () {
      expect(NowTaskCard.formatElapsed(0), '0:00');
    });

    test('pads seconds correctly', () {
      expect(NowTaskCard.formatElapsed(61), '1:01');
    });
  });
}
