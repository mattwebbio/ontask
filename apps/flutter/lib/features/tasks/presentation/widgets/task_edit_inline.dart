import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/energy_requirement.dart';
import '../../domain/task.dart';
import '../../domain/task_priority.dart';
import '../../domain/time_window.dart';
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
    _onFieldsChanged({field: value});
  }

  void _onFieldsChanged(Map<String, dynamic> fields) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(tasksProvider(
            listId: widget.task.listId,
            sectionId: widget.task.sectionId,
          ).notifier)
          .updateTask(widget.task.id, fields);
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
                  child: const Text(AppStrings.actionDone),
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

  void _showTimeWindowPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.taskTimeWindowLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldsChanged({
                'timeWindow': null,
                'timeWindowStart': null,
                'timeWindowEnd': null,
              });
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.actionNone),
          ),
          for (final tw in TimeWindow.values)
            CupertinoActionSheetAction(
              onPressed: () {
                if (tw == TimeWindow.custom) {
                  _onFieldChanged('timeWindow', tw.toJson());
                  Navigator.of(context).pop();
                  _showCustomTimeRangePicker();
                } else {
                  _onFieldsChanged({
                    'timeWindow': tw.toJson(),
                    'timeWindowStart': null,
                    'timeWindowEnd': null,
                  });
                  Navigator.of(context).pop();
                }
                setState(() {});
              },
              child: Text(_timeWindowLabel(tw)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  String _timeWindowLabel(TimeWindow tw) {
    switch (tw) {
      case TimeWindow.morning:
        return AppStrings.taskTimeWindowMorning;
      case TimeWindow.afternoon:
        return AppStrings.taskTimeWindowAfternoon;
      case TimeWindow.evening:
        return AppStrings.taskTimeWindowEvening;
      case TimeWindow.custom:
        return AppStrings.taskTimeWindowCustom;
    }
  }

  void _showCustomTimeRangePicker() {
    // Parse existing values or use defaults
    DateTime startTime = _parseTimeString(widget.task.timeWindowStart) ??
        DateTime(2026, 1, 1, 9, 0);
    DateTime endTime = _parseTimeString(widget.task.timeWindowEnd) ??
        DateTime(2026, 1, 1, 11, 0);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<OnTaskColors>()!;
        return Container(
          height: 360,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text(AppStrings.actionDone),
                    onPressed: () {
                      final start =
                          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                      final end =
                          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
                      _onFieldsChanged({
                        'timeWindowStart': start,
                        'timeWindowEnd': end,
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  AppStrings.taskTimeWindowCustomStart,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ),
              SizedBox(
                height: 120,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: startTime,
                  onDateTimeChanged: (date) {
                    startTime = date;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  AppStrings.taskTimeWindowCustomEnd,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ),
              SizedBox(
                height: 120,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: endTime,
                  onDateTimeChanged: (date) {
                    endTime = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Parses an HH:mm string into a DateTime for the time picker.
  DateTime? _parseTimeString(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(2026, 1, 1, hour, minute);
  }

  void _showEnergyPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.taskEnergyLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('energyRequirement', null);
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.actionNone),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('energyRequirement', EnergyRequirement.highFocus.toJson());
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskEnergyHighFocus),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('energyRequirement', EnergyRequirement.lowEnergy.toJson());
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskEnergyLowEnergy),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('energyRequirement', EnergyRequirement.flexible.toJson());
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskEnergyFlexible),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  void _showPriorityPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.taskPriorityLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('priority', TaskPriority.normal.toJson());
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskPriorityNormal),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('priority', TaskPriority.high.toJson());
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskPriorityHigh),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldChanged('priority', TaskPriority.critical.toJson());
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskPriorityCritical),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  String _energyLabel(EnergyRequirement energy) {
    switch (energy) {
      case EnergyRequirement.highFocus:
        return AppStrings.taskEnergyHighFocus;
      case EnergyRequirement.lowEnergy:
        return AppStrings.taskEnergyLowEnergy;
      case EnergyRequirement.flexible:
        return AppStrings.taskEnergyFlexible;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.normal:
        return AppStrings.taskPriorityNormal;
      case TaskPriority.high:
        return AppStrings.taskPriorityHigh;
      case TaskPriority.critical:
        return AppStrings.taskPriorityCritical;
    }
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
          const SizedBox(height: AppSpacing.md),

          // Time window picker
          GestureDetector(
            onTap: _showTimeWindowPicker,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.task.timeWindow != null
                      ? '${AppStrings.taskTimeWindowLabel}: ${_timeWindowLabel(widget.task.timeWindow!)}'
                      : AppStrings.taskTimeWindowLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Energy requirement picker
          GestureDetector(
            onTap: _showEnergyPicker,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.bolt,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.task.energyRequirement != null
                      ? '${AppStrings.taskEnergyLabel}: ${_energyLabel(widget.task.energyRequirement!)}'
                      : AppStrings.taskEnergyLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Priority picker
          GestureDetector(
            onTap: _showPriorityPicker,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.flag,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.task.priority != null && widget.task.priority != TaskPriority.normal
                      ? '${AppStrings.taskPriorityLabel}: ${_priorityLabel(widget.task.priority!)}'
                      : AppStrings.taskPriorityLabel,
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
                child: const Text(AppStrings.actionDone),
              ),
            ),
        ],
      ),
    );
  }
}
