import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/energy_requirement.dart';
import '../../domain/task.dart';
import '../../domain/task_priority.dart';
import '../../domain/time_window.dart';

/// Renders a single task row in a list.
///
/// Displays title and optional due date badge. Tap opens inline edit mode.
/// Swipe left reveals archive action.
class TaskRow extends StatelessWidget {
  const TaskRow({
    required this.task,
    this.onTap,
    this.onArchive,
    super.key,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onArchive?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: CupertinoColors.destructiveRed,
        child: Text(
          AppStrings.archiveTaskAction,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CupertinoColors.white,
              ),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.surfaceSecondary,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: task.archivedAt != null
                                ? colors.textSecondary
                                : colors.textPrimary,
                            decoration: task.archivedAt != null
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (task.dueDate != null || _hasSchedulingHints) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (task.dueDate != null)
                            Text(
                              _formatDueDate(task.dueDate!),
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                            ),
                          if (task.priority == TaskPriority.high ||
                              task.priority == TaskPriority.critical)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.flag_fill,
                                  size: 12,
                                  color: task.priority == TaskPriority.critical
                                      ? CupertinoColors.destructiveRed
                                      : CupertinoColors.systemOrange,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  task.priority == TaskPriority.critical
                                      ? AppStrings.taskPriorityCritical
                                      : AppStrings.taskPriorityHigh,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: task.priority == TaskPriority.critical
                                            ? CupertinoColors.destructiveRed
                                            : CupertinoColors.systemOrange,
                                      ),
                                ),
                              ],
                            ),
                          if (task.timeWindow != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _timeWindowBadgeLabel(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          if (task.energyRequirement != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.bolt,
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _energyBadgeLabel(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasSchedulingHints =>
      (task.priority == TaskPriority.high || task.priority == TaskPriority.critical) ||
      task.timeWindow != null ||
      task.energyRequirement != null;

  String _formatDueDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _timeWindowBadgeLabel() {
    switch (task.timeWindow!) {
      case TimeWindow.morning:
        return AppStrings.taskTimeWindowMorning;
      case TimeWindow.afternoon:
        return AppStrings.taskTimeWindowAfternoon;
      case TimeWindow.evening:
        return AppStrings.taskTimeWindowEvening;
      case TimeWindow.custom:
        if (task.timeWindowStart != null && task.timeWindowEnd != null) {
          return '${task.timeWindowStart} – ${task.timeWindowEnd}';
        }
        return AppStrings.taskTimeWindowCustom;
    }
  }

  String _energyBadgeLabel() {
    switch (task.energyRequirement!) {
      case EnergyRequirement.highFocus:
        return AppStrings.taskEnergyHighFocus;
      case EnergyRequirement.lowEnergy:
        return AppStrings.taskEnergyLowEnergy;
      case EnergyRequirement.flexible:
        return AppStrings.taskEnergyFlexible;
    }
  }
}
