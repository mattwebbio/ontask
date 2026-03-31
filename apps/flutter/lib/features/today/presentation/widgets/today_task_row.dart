import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, Theme;

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Visual states for a task row in the Today tab.
///
/// Determines styling (opacity, accent, badge) and swipe behaviour.
enum TodayTaskRowState {
  /// Default — full opacity, swipeable.
  upcoming,

  /// Current time window — subtle left accent border.
  current,

  /// Past due — amber overdue badge.
  overdue,

  /// Completed — strikethrough, muted.
  completed,

  /// Calendar event — grey dot, read-only, no swipe.
  calendarEvent,
}

/// Purpose-built row for the Today tab.
///
/// Layout: 40pt time label (right-aligned) | task title | trailing status.
/// NOT reusing [TaskRow] from lists — different layout and swipe semantics.
class TodayTaskRow extends StatelessWidget {
  final String taskId;
  final String title;
  final String timeLabel;
  final TodayTaskRowState rowState;
  final VoidCallback? onComplete;
  final VoidCallback? onReschedule;

  const TodayTaskRow({
    required this.taskId,
    required this.title,
    required this.timeLabel,
    required this.rowState,
    this.onComplete,
    this.onReschedule,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final isCompleted = rowState == TodayTaskRowState.completed;
    final isCalendarEvent = rowState == TodayTaskRowState.calendarEvent;
    final isCurrent = rowState == TodayTaskRowState.current;
    final isMuted = isCompleted || isCalendarEvent;

    final rowContent = Semantics(
      label: '$timeLabel, $title, ${_accessibilityStatus()}',
      child: Container(
        decoration: isCurrent
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: colors.accentPrimary,
                    width: 3,
                  ),
                ),
              )
            : null,
        padding: EdgeInsets.only(
          left: isCurrent ? AppSpacing.md : AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // 40pt time label column (right-aligned)
            SizedBox(
              width: 40,
              child: Text(
                timeLabel,
                textAlign: TextAlign.right,
                style: textTheme.bodySmall?.copyWith(
                  color: isMuted
                      ? colors.textSecondary.withValues(alpha: 0.5)
                      : colors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Task title
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  color: isMuted
                      ? colors.textPrimary.withValues(alpha: 0.5)
                      : colors.textPrimary,
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  fontSize: 15,
                ),
              ),
            ),
            // Trailing status indicator
            _buildStatusIndicator(colors),
          ],
        ),
      ),
    );

    // Calendar events are read-only (no swipe)
    if (isCalendarEvent || isCompleted) {
      return rowContent;
    }

    return Dismissible(
      key: ValueKey('today_task_$taskId'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        color: colors.scheduleHealthy,
        child: const Icon(CupertinoIcons.check_mark, color: CupertinoColors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: colors.accentPrimary,
        child: const Icon(CupertinoIcons.calendar, color: CupertinoColors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete?.call();
          return false; // Don't remove from tree — state update handles it
        } else if (direction == DismissDirection.endToStart) {
          onReschedule?.call();
          return false;
        }
        return false;
      },
      child: rowContent,
    );
  }

  Widget _buildStatusIndicator(OnTaskColors colors) {
    switch (rowState) {
      case TodayTaskRowState.completed:
        return Icon(
          CupertinoIcons.check_mark_circled_solid,
          size: 18,
          color: colors.textSecondary.withValues(alpha: 0.5),
        );
      case TodayTaskRowState.overdue:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colors.scheduleAtRisk.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            AppStrings.scheduleHealthAtRisk,
            style: TextStyle(
              color: colors.scheduleAtRisk,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case TodayTaskRowState.calendarEvent:
        return Icon(
          CupertinoIcons.circle_fill,
          size: 8,
          color: Colors.grey.withValues(alpha: 0.5),
        );
      case TodayTaskRowState.current:
      case TodayTaskRowState.upcoming:
        return const SizedBox.shrink();
    }
  }

  String _accessibilityStatus() {
    switch (rowState) {
      case TodayTaskRowState.upcoming:
        return AppStrings.scheduleHealthOnTrack;
      case TodayTaskRowState.current:
        return AppStrings.scheduleHealthOnTrack;
      case TodayTaskRowState.overdue:
        return AppStrings.scheduleHealthAtRisk;
      case TodayTaskRowState.completed:
        return AppStrings.todayTaskCompleted;
      case TodayTaskRowState.calendarEvent:
        return AppStrings.scheduleHealthOnTrack;
    }
  }
}
