import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_proof_sheet.dart';

void main() {
  // TaskProofSheet is a plain StatelessWidget — no provider overrides needed.
  // Data is passed directly via constructor.
  Widget buildSheet({
    required String taskId,
    String? proofMediaUrl,
    String? completedByName,
    DateTime? completedAt,
  }) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: TaskProofSheet(
          taskId: taskId,
          proofMediaUrl: proofMediaUrl,
          completedByName: completedByName,
          completedAt: completedAt,
        ),
      ),
    );
  }

  group('TaskProofSheet (Story 5.5, AC1)', () {
    testWidgets('renders sheet title', (tester) async {
      await tester.pumpWidget(buildSheet(taskId: 'task-id'));
      expect(find.text(AppStrings.proofDetailTitle), findsOneWidget);
    });

    testWidgets('renders privacy note footer', (tester) async {
      await tester.pumpWidget(buildSheet(taskId: 'task-id'));
      expect(find.text(AppStrings.proofPrivacyNote), findsOneWidget);
    });

    testWidgets('renders close button with xmark icon', (tester) async {
      await tester.pumpWidget(buildSheet(taskId: 'task-id'));
      // The close button is a CupertinoButton with the xmark icon
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    });

    testWidgets('shows Image.network when proofMediaUrl is non-null',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        taskId: 'task-id',
        proofMediaUrl: 'https://placehold.co/600x400.jpg',
      ));
      await tester.pump(); // Allow image builder to run
      // Image.network widget should be present in the tree
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
        'shows proofNotAvailableMessage when proofMediaUrl is null',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        taskId: 'task-id',
        proofMediaUrl: null,
      ));
      expect(find.text(AppStrings.proofNotAvailableMessage), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
