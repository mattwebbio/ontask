import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom bar shown during multi-select mode with bulk action buttons.
///
/// Actions: Reschedule, Complete, Delete, Assign (disabled — Epic 5 deferred).
/// Delete and Complete show a confirmation dialog before executing.
/// Reschedule opens a CupertinoDatePicker.
class BulkActionsBar extends StatelessWidget {
  const BulkActionsBar({
    required this.selectedCount,
    required this.onReschedule,
    required this.onComplete,
    required this.onDelete,
    super.key,
  });

  final int selectedCount;
  final ValueChanged<String> onReschedule;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  void _showReschedulePicker(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text(AppStrings.actionDone),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onReschedule(selectedDate.toUtc().toIso8601String());
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime:
                    DateTime.now().add(const Duration(days: 1)),
                onDateTimeChanged: (date) {
                  selectedDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteConfirmation(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppStrings.bulkCompleteConfirmTitle
            .replaceAll('{count}', '$selectedCount')),
        content: const Text(AppStrings.bulkCompleteConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onComplete();
            },
            child: const Text(AppStrings.bulkCompleteAction),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppStrings.bulkDeleteConfirmTitle
            .replaceAll('{count}', '$selectedCount')),
        content: const Text(AppStrings.bulkDeleteConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text(AppStrings.bulkDeleteAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        border: Border(
          top: BorderSide(
            color: colors.surfaceSecondary,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reschedule
          _BulkActionButton(
            icon: CupertinoIcons.calendar,
            label: AppStrings.bulkRescheduleAction,
            onPressed: () => _showReschedulePicker(context),
            color: colors.accentPrimary,
          ),
          // Complete
          _BulkActionButton(
            icon: CupertinoIcons.checkmark,
            label: AppStrings.bulkCompleteAction,
            onPressed: () => _showCompleteConfirmation(context),
            color: colors.accentPrimary,
          ),
          // Delete
          _BulkActionButton(
            icon: CupertinoIcons.trash,
            label: AppStrings.bulkDeleteAction,
            onPressed: () => _showDeleteConfirmation(context),
            color: CupertinoColors.destructiveRed,
          ),
          // Assign (disabled — Epic 5 deferred)
          Tooltip(
            message: AppStrings.bulkAssignDisabled,
            child: _BulkActionButton(
              icon: CupertinoIcons.person,
              label: AppStrings.bulkAssignAction,
              onPressed: null,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveColor = isDisabled ? color.withValues(alpha: 0.4) : color;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: effectiveColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: effectiveColor,
                ),
          ),
        ],
      ),
    );
  }
}
