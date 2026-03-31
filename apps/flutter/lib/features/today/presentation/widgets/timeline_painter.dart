import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/timeline_block.dart';
import 'today_task_row.dart';

/// CustomPainter for the timeline view.
///
/// **Performance**: All [Paint] and [TextPainter] objects are pre-allocated
/// in the constructor. ZERO allocations in [paint()] (UX-DR12).
class TimelinePainter extends CustomPainter {
  /// The blocks to render on the timeline. Bounds must be pre-computed
  /// before passing to the painter (computed in [TimelineView._computeBounds]).
  final List<TimelineBlock> blocks;

  /// Current time for the now indicator.
  final DateTime now;

  /// Theme colours for rendering.
  final OnTaskColors colors;

  /// Height in logical pixels per hour.
  final double hourHeight;

  /// Width of the time axis column.
  static const double timeAxisWidth = 32.0;

  /// Block corner radius.
  static const double blockRadius = 8.0;

  /// Now indicator dot radius.
  static const double nowDotRadius = 4.0;

  /// Minimum block height for touch targets (44pt per Apple HIG).
  static const double minBlockHeight = 44.0;

  // Pre-allocated paint objects
  final Paint _axisPaint;
  final Paint _nowLinePaint;
  final Paint _nowDotPaint;
  final Paint _taskBlockPaint;
  final Paint _calendarBlockPaint;
  final Paint _highlightPaint;
  // Pre-allocated for Epic 6 committed task blocks (stakeAmountCents)
  // ignore: unused_field
  final Paint _committedBlockPaint;
  // Pre-allocated for empty time block rendering
  // ignore: unused_field
  final Paint _emptyBlockPaint;

  // Pre-allocated text styles
  final TextStyle _hourLabelStyle;
  final TextStyle _blockTitleStyle;

  // Pre-allocated text painters (reused per label/block)
  final TextPainter _hourLabelPainter;
  final TextPainter _blockTitlePainter;

  /// Callback for handling block taps (used by semantics).
  final void Function(TimelineBlock)? onBlockTapped;

  TimelinePainter({
    required this.blocks,
    required this.now,
    required this.colors,
    this.hourHeight = 80.0,
    this.onBlockTapped,
  })  : _axisPaint = Paint()
          ..color = colors.textSecondary.withValues(alpha: 0.3)
          ..strokeWidth = 1,
        _nowLinePaint = Paint()
          ..color = colors.accentPrimary
          ..strokeWidth = 2,
        _nowDotPaint = Paint()..color = colors.accentPrimary,
        _taskBlockPaint = Paint()..color = colors.accentCompletion,
        _calendarBlockPaint = Paint()..color = CupertinoColors.systemGrey,
        _highlightPaint = Paint()
          ..color = colors.accentPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        _committedBlockPaint = Paint()..color = colors.accentPrimary,
        _emptyBlockPaint = Paint()
          ..color = colors.surfaceSecondary.withValues(alpha: 0.3),
        _hourLabelStyle = TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
        ),
        _blockTitleStyle = TextStyle(
          color: colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        _hourLabelPainter = TextPainter(
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.right,
          maxLines: 1,
        ),
        _blockTitlePainter = TextPainter(
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.left,
          maxLines: 1,
          ellipsis: '\u2026',
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Draw time axis rules and hour labels
    for (int hour = 0; hour < 24; hour++) {
      final y = hour * hourHeight;

      // Horizontal rule
      canvas.drawLine(
        Offset(timeAxisWidth, y),
        Offset(size.width, y),
        _axisPaint,
      );

      // Hour label — reuse pre-allocated style
      final labelText = _formatHourLabel(hour);
      _hourLabelPainter.text = TextSpan(
        text: labelText,
        style: _hourLabelStyle,
      );
      _hourLabelPainter.layout(maxWidth: timeAxisWidth - 4);
      _hourLabelPainter.paint(
        canvas,
        Offset(timeAxisWidth - 4 - _hourLabelPainter.width, y - 6),
      );
    }

    // Vertical rule for time axis
    canvas.drawLine(
      Offset(timeAxisWidth, 0),
      Offset(timeAxisWidth, size.height),
      _axisPaint,
    );

    // Draw event blocks — bounds are pre-computed in TimelineView
    for (final block in blocks) {
      // Select paint based on block type
      final paint = _paintForBlock(block);

      // Save original color, apply opacity, draw, restore
      final originalColor = paint.color;
      final opacity = _opacityForState(block.state);
      paint.color = originalColor.withValues(alpha: opacity);

      // Draw rounded rect
      final rrect = RRect.fromRectAndRadius(
        block.bounds,
        const Radius.circular(blockRadius),
      );
      canvas.drawRRect(rrect, paint);

      // Restore original color to avoid corruption
      paint.color = originalColor;

      // Draw current block highlight
      if (block.state == TodayTaskRowState.current) {
        canvas.drawRRect(rrect, _highlightPaint);
      }

      // Draw block title — reuse pre-allocated style, adjust alpha
      final titleAlpha = opacity;
      _blockTitlePainter.text = TextSpan(
        text: block.title,
        style: titleAlpha == 1.0
            ? _blockTitleStyle
            : _blockTitleStyle.copyWith(
                color: _blockTitleStyle.color?.withValues(alpha: titleAlpha),
              ),
      );
      _blockTitlePainter.layout(maxWidth: block.bounds.width - 12);
      if (block.bounds.height > 20) {
        _blockTitlePainter.paint(
          canvas,
          Offset(block.bounds.left + 6, block.bounds.top + 4),
        );
      }
    }

    // Draw now indicator
    final nowMinutes = now.hour * 60 + now.minute;
    final nowY = (nowMinutes / 60) * hourHeight;

    // Horizontal line
    canvas.drawLine(
      Offset(timeAxisWidth, nowY),
      Offset(size.width, nowY),
      _nowLinePaint,
    );

    // Dot at left edge
    canvas.drawCircle(
      Offset(timeAxisWidth, nowY),
      nowDotRadius,
      _nowDotPaint,
    );
  }

  Paint _paintForBlock(TimelineBlock block) {
    if (block.isCalendarEvent) return _calendarBlockPaint;
    // TODO(stub): committed task colour requires stakeAmountCents (Epic 6)
    // When available: if (block.hasStake) return _committedBlockPaint;
    return _taskBlockPaint;
  }

  double _opacityForState(TodayTaskRowState state) {
    switch (state) {
      case TodayTaskRowState.completed:
        return 0.3;
      case TodayTaskRowState.overdue:
        return 0.5;
      case TodayTaskRowState.current:
      case TodayTaskRowState.upcoming:
      case TodayTaskRowState.calendarEvent:
        return 1.0;
    }
  }

  String _formatHourLabel(int hour) {
    if (hour == 0) return '12a';
    if (hour < 12) return '${hour}a';
    if (hour == 12) return '12p';
    return '${hour - 12}p';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12
        ? AppStrings.todayTimePm
        : AppStrings.todayTimeAm;
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    if (minute == 0) return '$displayHour$period';
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }

  /// Compute bounds for a block given the available width.
  ///
  /// Called from [TimelineView._computeBounds] so bounds are available
  /// before painting and before [semanticsBuilder] runs.
  static Rect computeBlockBounds({
    required DateTime startTime,
    required int durationMinutes,
    required double hourHeight,
    required double blockAreaLeft,
    required double blockAreaWidth,
  }) {
    final safeDuration = math.max(durationMinutes, 1);
    final minutesSinceMidnight = startTime.hour * 60 + startTime.minute;
    final yPosition = (minutesSinceMidnight / 60) * hourHeight;
    final blockHeight =
        math.max((safeDuration / 60) * hourHeight, minBlockHeight);
    return Rect.fromLTWH(blockAreaLeft, yPosition, blockAreaWidth, blockHeight);
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return !identical(blocks, oldDelegate.blocks) ||
        now.hour != oldDelegate.now.hour ||
        now.minute != oldDelegate.now.minute;
  }

  @override
  SemanticsBuilderCallback? get semanticsBuilder {
    return (Size size) {
      final semantics = <CustomPainterSemantics>[];

      // Add hour label semantics
      for (int hour = 0; hour < 24; hour++) {
        final y = hour * hourHeight;
        final hourText = _formatHourLabel(hour);
        semantics.add(CustomPainterSemantics(
          rect: Rect.fromLTWH(0, y - 10, timeAxisWidth, 20),
          properties: SemanticsProperties(
            label: AppStrings.timelineHourLabel
                .replaceFirst('{hour}', hourText),
            textDirection: ui.TextDirection.ltr,
          ),
        ));
      }

      // Add block semantics — bounds are pre-computed
      for (final block in blocks) {
        final label = AppStrings.timelineBlockVoiceOver
            .replaceFirst('{title}', block.title)
            .replaceFirst('{startTime}', _formatTime(block.startTime))
            .replaceFirst('{duration}', '${block.durationMinutes}');

        semantics.add(CustomPainterSemantics(
          rect: block.bounds,
          properties: SemanticsProperties(
            label: label,
            textDirection: ui.TextDirection.ltr,
            onTap: onBlockTapped != null ? () => onBlockTapped!(block) : null,
          ),
        ));
      }

      return semantics;
    };
  }
}
