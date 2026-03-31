import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../../core/theme/app_theme.dart';
import '../../../tasks/domain/task.dart';
import '../../domain/timeline_block.dart';
import 'timeline_painter.dart';
import 'today_task_row.dart';

/// Timeline view that renders tasks as time-proportional blocks using
/// [CustomPainter] inside a [SingleChildScrollView].
///
/// Follows UX-DR12: full CustomPainter build, RepaintBoundary, zero
/// allocations in paint().
class TimelineView extends StatefulWidget {
  /// Tasks to render as timeline blocks.
  final List<Task> tasks;

  /// Callback when a block is tapped. Stub for now -- task detail navigation
  /// is deferred to a later story.
  final void Function(TimelineBlock)? onBlockTapped;

  /// Height in logical pixels per hour.
  final double hourHeight;

  const TimelineView({
    required this.tasks,
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
    if (!identical(widget.tasks, oldWidget.tasks)) {
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
    return widget.tasks.map((task) {
      final startTime = task.scheduledStartTime ?? task.dueDate ?? _now;
      final duration = task.durationMinutes ?? 30;
      final state = _determineState(task);

      return TimelineBlock(
        taskId: task.id,
        title: task.title,
        bounds: Rect.zero, // Will be computed by painter
        startTime: startTime,
        durationMinutes: duration,
        isCalendarEvent: state == TodayTaskRowState.calendarEvent,
        state: state,
      );
    }).toList();
  }

  TodayTaskRowState _determineState(Task task) {
    if (task.completedAt != null) return TodayTaskRowState.completed;
    if (task.dueDate != null && task.dueDate!.isBefore(_now)) {
      return TodayTaskRowState.overdue;
    }
    // TODO(stub): calendarEvent and current detection require real scheduling data
    return TodayTaskRowState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final totalHeight = 24 * widget.hourHeight;

    return SingleChildScrollView(
      controller: _scrollController,
      child: RepaintBoundary(
        child: GestureDetector(
          onTapDown: (details) {
            final tappedBlock = _blocks.cast<TimelineBlock?>().firstWhere(
                  (b) => b!.bounds.contains(details.localPosition),
                  orElse: () => null,
                );
            if (tappedBlock != null) {
              widget.onBlockTapped?.call(tappedBlock);
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
            size: Size(double.infinity, totalHeight),
          ),
        ),
      ),
    );
  }
}
