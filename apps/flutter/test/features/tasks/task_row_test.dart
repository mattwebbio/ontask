import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/now/domain/proof_mode.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_row.dart';

void main() {
  final baseTask = Task(
    id: 'a0000000-0000-4000-8000-000000000001',
    title: 'Test Task',
    position: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Widget buildRow(Task task) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: TaskRow(task: task),
      ),
    );
  }

  group('TaskRow — proof mode badge (Story 5.4, AC1, AC2)', () {
    testWidgets(
        'shows "Photo proof" label when proofMode is photo and proofModeIsCustom is false',
        (tester) async {
      final task = baseTask.copyWith(
        proofMode: ProofMode.photo,
        proofModeIsCustom: false,
      );

      await tester.pumpWidget(buildRow(task));

      expect(find.text(AppStrings.accountabilityPhoto), findsOneWidget);
      // No "Custom" badge when proofModeIsCustom is false
      expect(find.text(AppStrings.accountabilityCustomBadge), findsNothing);
    });

    testWidgets(
        'shows both the label and "Custom" badge when proofMode is photo and proofModeIsCustom is true',
        (tester) async {
      final task = baseTask.copyWith(
        proofMode: ProofMode.photo,
        proofModeIsCustom: true,
      );

      await tester.pumpWidget(buildRow(task));

      expect(find.text(AppStrings.accountabilityPhoto), findsOneWidget);
      expect(find.text(AppStrings.accountabilityCustomBadge), findsOneWidget);
    });

    testWidgets('shows no proof indicator when proofMode is standard',
        (tester) async {
      final task = baseTask.copyWith(
        proofMode: ProofMode.standard,
        proofModeIsCustom: false,
      );

      await tester.pumpWidget(buildRow(task));

      expect(find.text(AppStrings.accountabilityPhoto), findsNothing);
      expect(find.text(AppStrings.accountabilityWatchMode), findsNothing);
      expect(find.text(AppStrings.accountabilityHealthKit), findsNothing);
      expect(find.text(AppStrings.accountabilityCustomBadge), findsNothing);
    });
  });
}
