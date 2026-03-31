import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';

/// Modal picker that lists tasks available to add as a dependency.
///
/// Excludes the current task and already-linked tasks from the list.
/// Tapping a task triggers [onSelected] and dismisses the picker.
class DependencyPicker extends StatelessWidget {
  const DependencyPicker({
    required this.availableTasks,
    required this.onSelected,
    super.key,
  });

  /// Tasks available to be linked as dependencies (pre-filtered to exclude
  /// the current task and already-linked tasks).
  final List<Task> availableTasks;

  /// Called when the user taps a task to add as a dependency.
  final ValueChanged<Task> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              AppStrings.taskDependencyPickerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
            ),
          ),
          if (availableTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                AppStrings.taskDependencyPickerEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableTasks.length,
                itemBuilder: (context, index) {
                  final task = availableTasks[index];
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => onSelected(task),
                    child: Container(
                      width: double.infinity,
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
                      child: Text(
                        task.title,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textPrimary,
                                ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
