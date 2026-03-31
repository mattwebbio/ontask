import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';

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
                    if (task.dueDate != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDueDate(task.dueDate!),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
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

  String _formatDueDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
