import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../lists/domain/task_list.dart';
import '../../lists/presentation/lists_provider.dart';
import '../../tasks/presentation/tasks_provider.dart';

/// Modal sheet shown when the Add action tab is tapped.
///
/// Opened by [AppShell] via [showModalBottomSheet] — this is NOT a persistent
/// navigation destination. The Add tab is an action tab, not a content tab.
///
/// Contains a task creation form: title field (required), notes field
/// (optional), due date picker, list picker, and submit button.
class AddTabSheet extends ConsumerStatefulWidget {
  const AddTabSheet({super.key});

  @override
  ConsumerState<AddTabSheet> createState() => _AddTabSheetState();
}

class _AddTabSheetState extends ConsumerState<AddTabSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedListId;
  bool _isSubmitting = false;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = AppStrings.addTaskTitleRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _titleError = null;
    });

    try {
      await ref
          .read(tasksProvider(listId: _selectedListId).notifier)
          .createTask(
            title: title,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            dueDate: _dueDate?.toIso8601String(),
            listId: _selectedListId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                initialDateTime: _dueDate ?? DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() => _dueDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showListPicker(List<TaskList> lists) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(AppStrings.addTaskListLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedListId = null);
              Navigator.of(context).pop();
            },
            child: const Text('None'),
          ),
          for (final list in lists)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedListId = list.id);
                Navigator.of(context).pop();
              },
              child: Text(list.title),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final listsState = ref.watch(listsProvider);
    final lists = listsState.value ?? <TaskList>[];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.sm,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: AppSpacing.xxxl,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  AppStrings.addTaskTitle,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title field (required)
                CupertinoTextField(
                  controller: _titleController,
                  placeholder: AppStrings.addTaskTitlePlaceholder,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                      ),
                  onChanged: (_) {
                    if (_titleError != null) {
                      setState(() => _titleError = null);
                    }
                  },
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _titleError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CupertinoColors.destructiveRed,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Notes field (optional)
                CupertinoTextField(
                  controller: _notesController,
                  placeholder: AppStrings.addTaskNotesPlaceholder,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Due date picker
                GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _dueDate != null
                              ? '${AppStrings.addTaskDueDateLabel}: ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                              : AppStrings.addTaskDueDateLabel,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // List picker
                if (lists.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _showListPicker(lists),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.collections,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _selectedListId != null
                                ? '${AppStrings.addTaskListLabel}: ${lists.where((l) => l.id == _selectedListId).firstOrNull?.title ?? ""}'
                                : AppStrings.addTaskListLabel,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _isSubmitting ? null : _createTask,
                    child: Text(
                      _isSubmitting ? '...' : AppStrings.addTaskCreateButton,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
