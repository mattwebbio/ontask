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

  Widget buildCard({required NowTask task, VoidCallback? onNudge}) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: NowTaskCard(
              task: task,
              onNudge: onNudge,
            ),
          ),
        ),
      ),
    );
  }

  group('NowTaskCard nudge button', () {
    testWidgets('does NOT show "Reschedule with AI" button when onNudge is null',
        (tester) async {
      await tester.pumpWidget(buildCard(task: testTask, onNudge: null));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.todayRowNudge), findsNothing);
    });

    testWidgets('shows "Reschedule with AI" button when onNudge is non-null',
        (tester) async {
      await tester.pumpWidget(buildCard(task: testTask, onNudge: () {}));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.todayRowNudge), findsOneWidget);
    });

    testWidgets('tapping "Reschedule with AI" fires onNudge callback',
        (tester) async {
      var nudgeCalled = false;
      await tester.pumpWidget(
        buildCard(task: testTask, onNudge: () => nudgeCalled = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.todayRowNudge));
      await tester.pump();
      expect(nudgeCalled, true);
    });
  });
}
