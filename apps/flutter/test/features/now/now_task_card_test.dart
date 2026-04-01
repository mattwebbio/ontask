import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/now/domain/now_task.dart';
import 'package:ontask/features/now/domain/proof_mode.dart';
import 'package:ontask/features/now/presentation/widgets/now_task_card.dart';

// Tests for NowTaskCard attribution rendering (Story 5.3, AC2).
//
// NowTaskCard is a plain StatefulWidget — no provider overrides needed.
// Pass NowTask directly via constructor. Wrap in MaterialApp with OnTaskTheme.

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget buildCard(NowTask task) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: NowTaskCard(task: task),
          ),
        ),
      ),
    );
  }

  NowTask makeTask({
    String? listName,
    String? assignorName,
  }) {
    return NowTask(
      id: 'task-1',
      title: 'Clean the kitchen',
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
      listName: listName,
      assignorName: assignorName,
    );
  }

  NowTask makeCommittedTask({
    int stakeAmountCents = 2500,
    ProofMode proofMode = ProofMode.photo,
  }) {
    return NowTask(
      id: 'task-2',
      title: 'Exercise 30 minutes',
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
      stakeAmountCents: stakeAmountCents,
      proofMode: proofMode,
    );
  }

  group('NowTaskCard committed variant (Story 6.8, AC3)', () {
    testWidgets(
        'renders committed variant (dark surface) when stakeAmountCents is set',
        (tester) async {
      final task = makeCommittedTask(
        stakeAmountCents: 2500,
        proofMode: ProofMode.photo,
      );

      await tester.pumpWidget(buildCard(task));
      await tester.pump();

      // Verify the accentCommitment color is applied as card background.
      final theme = AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay');
      final colors = theme.extension<OnTaskColors>()!;

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                colors.accentCommitment,
      );
      expect(containerFinder, findsAtLeastNWidgets(1));

      // Verify CommitmentRow is rendered with the formatted amount '$25'.
      expect(find.text('\$25'), findsOneWidget);
      // Verify "at stake" label from CommitmentRow.
      expect(find.text(AppStrings.nowCardStakeLabel), findsOneWidget);
    });
  });

  group('NowTaskCard attribution rendering (AC2)', () {
    testWidgets(
        'shows "From [listName] · assigned by [assignorName]" when both are set',
        (tester) async {
      final task = makeTask(listName: 'Household', assignorName: 'Jordan');

      await tester.pumpWidget(buildCard(task));
      await tester.pump();

      final expected = AppStrings.nowCardAttributionFromListAndAssignor
          .replaceAll('{listName}', 'Household')
          .replaceAll('{assignor}', 'Jordan');

      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('shows "From [listName]" when only listName is set',
        (tester) async {
      final task = makeTask(listName: 'Household', assignorName: null);

      await tester.pumpWidget(buildCard(task));
      await tester.pump();

      final expected = AppStrings.nowCardAttributionFromList
          .replaceAll('{listName}', 'Household');

      expect(find.text(expected), findsOneWidget);
    });

    testWidgets(
        'shows default attribution ("Your past self planned this for now") when neither field is set',
        (tester) async {
      final task = makeTask(listName: null, assignorName: null);

      await tester.pumpWidget(buildCard(task));
      await tester.pump();

      expect(find.text(AppStrings.nowCardAttribution), findsOneWidget);
    });
  });
}
