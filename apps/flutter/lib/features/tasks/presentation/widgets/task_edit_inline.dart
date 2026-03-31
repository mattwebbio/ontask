import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';
import '../tasks_provider.dart';

/// Inline editing widget for task properties.
///
/// Shows all editable fields (title, notes, due date).
/// Changes saved immediately via [TasksNotifier.updateTask()] on each field
/// change, debounced 300ms (FR58 — no separate save button).
class TaskEditInline extends ConsumerStatefulWidget {
  const TaskEditInline({
    required this.task,
    this.onDone,
    super.key,
  });

  final Task task;
  final VoidCallback? onDone;

  @override
  ConsumerState<TaskEditInline> createState() => _TaskEditInlineState();
}

class _TaskEditInlineState extends ConsumerState<TaskEditInline> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFieldChanged(String field, dynamic value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(tasksProvider(
            listId: widget.task.listId,
            sectionId: widget.task.sectionId,
          ).notifier)
          .updateTask(widget.task.id, {field: value});
    });
  }

  void _showDatePicker() {
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
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: widget.task.dueDate ?? DateTime.now(),
                onDateTimeChanged: (date) {
                  _onFieldChanged('dueDate', date.toIso8601String());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          CupertinoTextField(
            controller: _titleController,
            placeholder: AppStrings.taskTitlePlaceholder,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
            onChanged: (value) => _onFieldChanged('title', value),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.surfaceSecondary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Notes field
          CupertinoTextField(
            controller: _notesController,
            placeholder: AppStrings.editTaskNotes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
            maxLines: 3,
            onChanged: (value) => _onFieldChanged('notes', value),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.surfaceSecondary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Due date picker
          GestureDetector(
            onTap: _showDatePicker,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.task.dueDate != null
                      ? AppStrings.editTaskDueDate
                      : AppStrings.addTaskDueDateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Done button
          if (widget.onDone != null)
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onDone,
                child: const Text('Done'),
              ),
            ),
        ],
      ),
    );
  }
}
