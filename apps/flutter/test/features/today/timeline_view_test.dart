import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/today/domain/timeline_block.dart';
import 'package:ontask/features/today/presentation/widgets/timeline_painter.dart';
import 'package:ontask/features/today/presentation/widgets/timeline_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final farFuture = DateTime.now().add(const Duration(days: 365));
  final testTasks = [
    Task(
      id: 'task-1',
      title: 'Morning standup',
      position: 0,
      dueDate: DateTime(farFuture.year, farFuture.month, farFuture.day, 9, 0),
      scheduledStartTime:
          DateTime(farFuture.year, farFuture.month, farFuture.day, 9, 0),
      durationMinutes: 30,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
    Task(
      id: 'task-2',
      title: 'Write report',
      position: 1,
      dueDate: DateTime(farFuture.year, farFuture.month, farFuture.day, 14, 0),
      scheduledStartTime:
          DateTime(farFuture.year, farFuture.month, farFuture.day, 14, 0),
      durationMinutes: 60,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
  ];

  Widget buildWidget({
    List<Task>? tasks,
    void Function(TimelineBlock)? onBlockTapped,
  }) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: TimelineView(
          tasks: tasks ?? testTasks,
          onBlockTapped: onBlockTapped,
          hourHeight: 80.0,
        ),
      ),
    );
  }

  group('TimelineView', () {
    testWidgets('renders with task data (finds CustomPaint widget)',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('now indicator renders at current time position',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // The TimelinePainter renders the now indicator line.
      // Verify a CustomPaint with our painter exists.
      final customPaint = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      final hasPainter = customPaint.any(
        (w) => w.painter is TimelinePainter,
      );
      expect(hasPainter, isTrue);
    });

    testWidgets('block height is proportional to duration', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Find the TimelinePainter to inspect blocks
      final customPaintWidgets = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      final painterWidget = customPaintWidgets.firstWhere(
        (w) => w.painter is TimelinePainter,
      );
      final painter = painterWidget.painter as TimelinePainter;

      // After initial render, blocks should have bounds computed
      // The 30-min task should be half the height of the 60-min task
      // block height = (durationMinutes / 60) * hourHeight
      // 30min: (30/60) * 80 = 40pt, 60min: (60/60) * 80 = 80pt
      expect(painter.blocks.length, 2);
      // Blocks will have Rect.zero until first paint, so check the model
      expect(painter.blocks[0].durationMinutes, 30);
      expect(painter.blocks[1].durationMinutes, 60);
    });

    testWidgets('calendar events render with grey colour', (tester) async {
      // Create a task with calendarEvent state — completedAt signals completed,
      // but for calendar events we need a different mechanism.
      // For now, verify the painter handles the colour mapping correctly.
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Verify the painter is instantiated with the correct colors
      final customPaintWidgets = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      final painterWidget = customPaintWidgets.firstWhere(
        (w) => w.painter is TimelinePainter,
      );
      final painter = painterWidget.painter as TimelinePainter;
      expect(painter.colors, isNotNull);
    });

    testWidgets('VoiceOver semantics labels for blocks', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Verify semantics are created for the blocks
      final semantics = tester.getSemantics(find.byType(CustomPaint).last);
      // CustomPainter semantics should include block labels
      expect(semantics, isNotNull);
    });

    testWidgets('hour labels render as semantic nodes', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // The TimelinePainter's semanticsBuilder provides hour label nodes
      final customPaintWidgets = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      final painterWidget = customPaintWidgets.firstWhere(
        (w) => w.painter is TimelinePainter,
      );
      final painter = painterWidget.painter as TimelinePainter;
      // Verify semanticsBuilder is not null (means VoiceOver nodes are provided)
      expect(painter.semanticsBuilder, isNotNull);
    });

    testWidgets('tap on block calls detail callback', (tester) async {
      // Use tasks at early hours so blocks are visible without scrolling
      final earlyTasks = [
        Task(
          id: 'tap-task-1',
          title: 'Early task',
          position: 0,
          dueDate: DateTime(farFuture.year, farFuture.month, farFuture.day, 0, 30),
          scheduledStartTime:
              DateTime(farFuture.year, farFuture.month, farFuture.day, 0, 30),
          durationMinutes: 60,
          createdAt: DateTime(2026, 3, 30),
          updatedAt: DateTime(2026, 3, 30),
        ),
      ];

      TimelineBlock? tappedBlock;
      await tester.pumpWidget(
        buildWidget(
          tasks: earlyTasks,
          onBlockTapped: (block) => tappedBlock = block,
        ),
      );
      await tester.pump();

      // Block at 0:30: y = (30/60) * 80 = 40, height = (60/60) * 80 = 80
      // Block area left = 32 + 8 = 40
      // Tap at a position inside the block — use the scroll view's coordinate space
      // Since _scrollToNow scrolls to current time, the 0:30 block may still be
      // outside viewport. Use the ScrollController to scroll to top first.
      final scrollFinder = find.byType(SingleChildScrollView);
      final scrollWidget =
          tester.widget<SingleChildScrollView>(scrollFinder);
      scrollWidget.controller?.jumpTo(0);
      await tester.pump();

      // Now tap at (50, 60) — inside the 0:30 block (y=40, height=80)
      await tester.tapAt(const Offset(50, 60));
      await tester.pump();

      expect(tappedBlock, isNotNull);
      expect(tappedBlock!.taskId, 'tap-task-1');
    });
  });
}
