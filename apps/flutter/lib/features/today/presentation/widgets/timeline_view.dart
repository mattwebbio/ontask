import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/domain/task.dart';
import '../../data/calendar_event_dto.dart';
import '../../domain/timeline_block.dart';
import 'timeline_painter.dart';
import 'today_task_row.dart';

/// Timeline view that renders tasks as time-proportional blocks using
/// [CustomPainter] inside a [SingleChildScrollView].
///
/// Follows UX-DR12: full CustomPainter build, RepaintBoundary, zero
/// allocations in paint().
///
/// As of Story 3.4, also accepts [calendarBlocks] to display grey calendar
/// event blocks from Google Calendar (AC6). Task blocks navigate to the
/// task detail screen on tap (AC3); calendar event blocks show a brief
/// info sheet.
class TimelineView extends StatefulWidget {
  /// Tasks to render as timeline blocks.
  final List<Task> tasks;

  /// Calendar event blocks to display as grey immovable blocks (AC6, Story 3.4).
  final List<CalendarEventDto> calendarBlocks;

  /// Callback when a block is tapped. Wired in Story 3.4 to navigate to task
  /// detail for task blocks; calendar event blocks show an info sheet.
  final void Function(TimelineBlock)? onBlockTapped;

  /// Height in logical pixels per hour.
  final double hourHeight;

  const TimelineView({
    required this.tasks,
    this.calendarBlocks = const [],
    this.onBlockTapped,
    this.hourHeight = 80.0,
    super.key,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late final ScrollController _scrollController;
  late Timer _nowTimer;
  DateTime _now = DateTime.now();
  late List<TimelineBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _blocks = _buildBlocks();

    // Update now indicator every 60 seconds
    _nowTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });

    // Scroll to current time position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNow();
    });
  }

  @override
  void didUpdateWidget(covariant TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.tasks, oldWidget.tasks) ||
        !identical(widget.calendarBlocks, oldWidget.calendarBlocks)) {
      _blocks = _buildBlocks();
    }
  }

  @override
  void dispose() {
    _nowTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final nowMinutes = _now.hour * 60 + _now.minute;
    final yPosition = (nowMinutes / 60) * widget.hourHeight;
    final viewportHeight = MediaQuery.of(context).size.height;
    final targetOffset = (yPosition - viewportHeight / 3)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(targetOffset);
  }

  List<TimelineBlock> _buildBlocks() {
    // Task blocks
    final taskBlocks = widget.tasks.map((task) {
      final startTime = task.scheduledStartTime ?? task.dueDate ?? _now;
      final duration = task.durationMinutes ?? 30;
      final state = _determineState(task);

      return TimelineBlock(
        taskId: task.id,
        title: task.title,
        bounds: Rect.zero, // Computed in _computeBounds when width is known
        startTime: startTime,
        durationMinutes: duration,
        isCalendarEvent: false,
        state: state,
      );
    }).toList();

    // Calendar event blocks (grey, immovable — AC6)
    final calendarEventBlocks = widget.calendarBlocks.map((event) {
      final startTime = event.startDateTime;
      final endTime = event.endDateTime;
      final durationMinutes = endTime.difference(startTime).inMinutes.clamp(15, 480);

      return TimelineBlock(
        taskId: event.id, // Use event ID as stable identifier
        title: event.summary ?? AppStrings.timelineCalendarEvent,
        bounds: Rect.zero,
        startTime: startTime,
        durationMinutes: durationMinutes,
        isCalendarEvent: true,
        state: TodayTaskRowState.calendarEvent,
      );
    }).toList();

    return [...taskBlocks, ...calendarEventBlocks];
  }

  /// Compute bounds for all blocks using the available width.
  /// Called in [build] via [LayoutBuilder] so bounds are set before
  /// the painter and semanticsBuilder access them.
  void _computeBounds(double availableWidth) {
    final blockAreaLeft = TimelinePainter.timeAxisWidth + 8.0;
    final blockAreaWidth = availableWidth - blockAreaLeft - 8.0;

    for (final block in _blocks) {
      block.bounds = TimelinePainter.computeBlockBounds(
        startTime: block.startTime,
        durationMinutes: block.durationMinutes,
        hourHeight: widget.hourHeight,
        blockAreaLeft: blockAreaLeft,
        blockAreaWidth: blockAreaWidth,
      );
    }
  }

  TodayTaskRowState _determineState(Task task) {
    if (task.completedAt != null) return TodayTaskRowState.completed;
    if (task.dueDate != null && task.dueDate!.isBefore(_now)) {
      return TodayTaskRowState.overdue;
    }
    // TODO(stub): calendarEvent and current detection require real scheduling data
    return TodayTaskRowState.upcoming;
  }

  /// Handles a block tap — navigates to task detail for task blocks,
  /// shows an info sheet for calendar event blocks (AC3).
  void _handleBlockTapped(TimelineBlock block) {
    // Delegate to custom handler first (for testing / overrides)
    if (widget.onBlockTapped != null) {
      widget.onBlockTapped!(block);
      return;
    }

    if (!block.isCalendarEvent) {
      // Task block — navigate to task detail (AC3, FR79)
      context.push('/tasks/${block.taskId}');
    } else {
      // Calendar event block — show brief info sheet (do NOT navigate)
      showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(block.title),
          message: Text(AppStrings.timelineCalendarEvent),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final totalHeight = 24 * widget.hourHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute bounds before creating painter so semanticsBuilder
        // has correct rects (fixes VoiceOver Rect.zero bug)
        _computeBounds(constraints.maxWidth);

        return SingleChildScrollView(
          controller: _scrollController,
          child: RepaintBoundary(
            child: GestureDetector(
              onTapDown: (details) {
                final tappedBlock =
                    _blocks.cast<TimelineBlock?>().firstWhere(
                          (b) => b!.bounds.contains(details.localPosition),
                          orElse: () => null,
                        );
                if (tappedBlock != null) {
                  _handleBlockTapped(tappedBlock);
                }
              },
              child: CustomPaint(
                painter: TimelinePainter(
                  blocks: _blocks,
                  now: _now,
                  colors: colors,
                  hourHeight: widget.hourHeight,
                  onBlockTapped: widget.onBlockTapped,
                ),
                size: Size(constraints.maxWidth, totalHeight),
              ),
            ),
          ),
        );
      },
    );
  }
}
