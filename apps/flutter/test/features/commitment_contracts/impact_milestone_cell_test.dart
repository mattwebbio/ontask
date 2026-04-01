import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/domain/impact_milestone.dart';
import 'package:ontask/features/commitment_contracts/presentation/widgets/impact_milestone_cell.dart';

// Widget tests for ImpactMilestoneCell — Story 6.4 (FR27, AC1, AC2).

final _stubMilestone = ImpactMilestone(
  id: 'first-kept',
  title: 'First commitment kept.',
  body: 'You showed up when it mattered.',
  earnedAt: DateTime.utc(2026, 1, 15),
  shareText: 'I kept my first commitment with On Task.',
);

Widget _wrapCell({required ImpactMilestone milestone, VoidCallback? onShare}) {
  return MaterialApp(
    theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
    home: Scaffold(
      body: ImpactMilestoneCell(
        milestone: milestone,
        onShare: onShare ?? () {},
      ),
    ),
  );
}

void main() {
  group('ImpactMilestoneCell — content rendering', () {
    testWidgets('renders milestone title and body text', (tester) async {
      await tester.pumpWidget(_wrapCell(milestone: _stubMilestone));
      await tester.pumpAndSettle();

      expect(find.text('First commitment kept.'), findsOneWidget);
      expect(find.text('You showed up when it mattered.'), findsOneWidget);
    });

    testWidgets('renders earnedAt formatted as MMM d, yyyy', (tester) async {
      await tester.pumpWidget(_wrapCell(milestone: _stubMilestone));
      await tester.pumpAndSettle();

      // DateTime.utc(2026, 1, 15) → 'Jan 15, 2026'
      expect(find.text('Jan 15, 2026'), findsOneWidget);
    });
  });

  group('ImpactMilestoneCell — share button', () {
    testWidgets('share button calls onShare callback when tapped', (tester) async {
      var shareTapped = false;

      await tester.pumpWidget(
        _wrapCell(
          milestone: _stubMilestone,
          onShare: () => shareTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // Find the share button by its icon
      final shareButton = find.byIcon(CupertinoIcons.share);
      expect(shareButton, findsOneWidget);

      await tester.tap(shareButton);
      await tester.pump();

      expect(shareTapped, isTrue);
    });
  });
}
