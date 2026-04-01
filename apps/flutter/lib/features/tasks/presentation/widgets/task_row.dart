import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../lists/domain/list_member.dart';
import '../../../now/domain/proof_mode.dart';
import '../../../prediction/presentation/widgets/prediction_badge_async.dart';
import '../../domain/energy_requirement.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/task.dart';
import '../../domain/task_dependency.dart';
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
    this.dependsOn = const [],
    this.blocks = const [],
    this.allTasks = const [],
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onSelectionToggle,
    this.showPrediction = false,
    this.listMembers = const [],
    super.key,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;

  /// Dependencies where this task depends on another.
  final List<TaskDependency> dependsOn;

  /// Dependencies where this task blocks another.
  final List<TaskDependency> blocks;

  /// All tasks in the list — used to resolve dependency task titles.
  final List<Task> allTasks;

  /// Whether this task is selected in multi-select mode.
  final bool isSelected;

  /// Whether multi-select mode is active.
  final bool isMultiSelectMode;

  /// Called when the selection checkbox is toggled.
  final VoidCallback? onSelectionToggle;

  /// Whether to show the predicted completion badge in the trailing area.
  ///
  /// Defaults to false to avoid adding network calls to every task row.
  /// Set to true only in list detail view — not in search results or Today tab.
  final bool showPrediction;

  /// Members of the list, used to resolve assignee initials for the badge.
  ///
  /// Pass the list's members so the badge can show initials. If the member
  /// is not found or the list is empty, a generic person icon is shown.
  final List<ListMember> listMembers;

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
              // Multi-select checkbox
              if (isMultiSelectMode) ...[
                GestureDetector(
                  onTap: onSelectionToggle,
                  child: Icon(
                    isSelected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 22,
                    color: isSelected
                        ? colors.accentPrimary
                        : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
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
                    if (task.dueDate != null || _hasSchedulingHints || task.recurrenceRule != null || dependsOn.isNotEmpty || blocks.isNotEmpty) ...[
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
                          if (task.recurrenceRule != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.repeat,
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _recurrenceBadgeLabel(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          // Dependency indicators
                          if (dependsOn.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.link,
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _dependsOnLabel(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          if (blocks.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.lock,
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _blocksLabel(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          // Proof mode indicator — shown when proofMode != standard (AC1, AC2)
                          if (task.proofMode != ProofMode.standard)
                            Semantics(
                              label: task.proofModeIsCustom
                                  ? AppStrings.accountabilityCustomBadge
                                  : AppStrings.accountabilityInheritedLabel,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.shield,
                                    size: 12,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _proofModeBadgeLabel(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                  ),
                                  if (task.proofModeIsCustom) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppStrings.accountabilityCustomBadge,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (task.assignedToUserId != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _AssigneeBadge(
                  assignedToUserId: task.assignedToUserId!,
                  listMembers: listMembers,
                ),
              ],
              if (showPrediction) ...[
                const SizedBox(width: AppSpacing.sm),
                TaskPredictionBadge(taskId: task.id),
              ],
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
      task.energyRequirement != null ||
      task.proofMode != ProofMode.standard;

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

  String _recurrenceBadgeLabel() {
    switch (task.recurrenceRule!) {
      case RecurrenceRule.daily:
        return AppStrings.taskRecurrenceDaily;
      case RecurrenceRule.weekly:
        return AppStrings.taskRecurrenceWeekly;
      case RecurrenceRule.monthly:
        return AppStrings.taskRecurrenceMonthly;
      case RecurrenceRule.custom:
        if (task.recurrenceInterval != null) {
          return AppStrings.taskRecurrenceEveryNDays.replaceAll('{n}', '${task.recurrenceInterval}');
        }
        return AppStrings.taskRecurrenceCustom;
    }
  }

  String _dependsOnLabel() {
    if (dependsOn.length == 1) {
      final depTask = allTasks.where((t) => t.id == dependsOn.first.dependsOnTaskId).firstOrNull;
      return '${AppStrings.taskDependsOn}: ${depTask?.title ?? dependsOn.first.dependsOnTaskId}';
    }
    return AppStrings.taskDependsOnCount.replaceAll('{count}', '${dependsOn.length}');
  }

  String _blocksLabel() {
    if (blocks.length == 1) {
      final depTask = allTasks.where((t) => t.id == blocks.first.dependentTaskId).firstOrNull;
      return '${AppStrings.taskBlocks}: ${depTask?.title ?? blocks.first.dependentTaskId}';
    }
    return AppStrings.taskBlocksCount.replaceAll('{count}', '${blocks.length}');
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

  /// Returns the display label for the proof mode badge in the task row metadata.
  String _proofModeBadgeLabel() {
    switch (task.proofMode) {
      case ProofMode.photo:
        return AppStrings.accountabilityPhoto;
      case ProofMode.watchMode:
        return AppStrings.accountabilityWatchMode;
      case ProofMode.healthKit:
        return AppStrings.accountabilityHealthKit;
      case ProofMode.calendarEvent:
        return AppStrings.proofModeCalendarEvent;
      case ProofMode.standard:
        return '';
    }
  }
}

/// Small avatar-initials circle shown when a task has an assigned member.
///
/// Shows the member's initials if found in [listMembers]; falls back to a
/// generic person icon when the member is not loaded or not found.
/// Display-only in v1 — tapping does nothing.
class _AssigneeBadge extends StatelessWidget {
  const _AssigneeBadge({
    required this.assignedToUserId,
    required this.listMembers,
  });

  final String assignedToUserId;
  final List<ListMember> listMembers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final member = listMembers.where((m) => m.userId == assignedToUserId).firstOrNull;

    return Semantics(
      label: AppStrings.taskAssignedToLabel,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colors.accentPrimary,
          shape: BoxShape.circle,
        ),
        child: member != null
            ? Center(
                child: Text(
                  member.avatarInitials,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CupertinoColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            : const Icon(
                CupertinoIcons.person,
                size: 12,
                color: CupertinoColors.white,
              ),
      ),
    );
  }
}
