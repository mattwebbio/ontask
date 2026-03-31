import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/energy_requirement.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/task.dart';
import '../../domain/task_dependency.dart';
import '../../domain/task_priority.dart';
import '../../domain/time_window.dart';
import '../dependencies_provider.dart';
import '../tasks_provider.dart';
import 'dependency_picker.dart';

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
  /// Cached edit scope choice for recurring tasks: null = not chosen yet,
  /// true = edit all future, false = edit this instance only.
  bool? _editAllFuture;

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
    if (widget.task.recurrenceRule != null && _editAllFuture == null) {
      // Show edit scope choice before applying changes
      _showEditScopeChoice(fields);
      return;
    }
    _applyFields(fields);
  }

  void _showEditScopeChoice(Map<String, dynamic> fields) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.taskRecurrenceEditChoiceTitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _editAllFuture = false;
              Navigator.of(context).pop();
              _applyFields(fields);
            },
            child: const Text(AppStrings.taskRecurrenceEditThisInstance),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _editAllFuture = true;
              Navigator.of(context).pop();
              _applyFields({...fields, 'applyToFuture': true});
            },
            child: const Text(AppStrings.taskRecurrenceEditAllFuture),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  void _applyFields(Map<String, dynamic> fields) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final finalFields = Map<String, dynamic>.from(fields);
      if (_editAllFuture == true && !finalFields.containsKey('applyToFuture')) {
        finalFields['applyToFuture'] = true;
      }
      ref
          .read(tasksProvider(
            listId: widget.task.listId,
            sectionId: widget.task.sectionId,
          ).notifier)
          .updateTask(widget.task.id, finalFields);
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

  void _showRecurrencePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.taskRecurrenceLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldsChanged({
                'recurrenceRule': null,
                'recurrenceInterval': null,
                'recurrenceDaysOfWeek': null,
              });
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.actionNone),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldsChanged({
                'recurrenceRule': 'daily',
                'recurrenceInterval': null,
                'recurrenceDaysOfWeek': null,
              });
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskRecurrenceDaily),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldsChanged({'recurrenceRule': 'weekly'});
              Navigator.of(context).pop();
              _showWeeklyDayPicker();
              setState(() {});
            },
            child: const Text(AppStrings.taskRecurrenceWeekly),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldsChanged({
                'recurrenceRule': 'monthly',
                'recurrenceInterval': null,
                'recurrenceDaysOfWeek': null,
              });
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(AppStrings.taskRecurrenceMonthly),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _onFieldsChanged({'recurrenceRule': 'custom'});
              Navigator.of(context).pop();
              _showCustomIntervalPicker();
              setState(() {});
            },
            child: const Text(AppStrings.taskRecurrenceCustom),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  void _showWeeklyDayPicker() {
    final dayNames = [
      AppStrings.taskDayMonday,
      AppStrings.taskDayTuesday,
      AppStrings.taskDayWednesday,
      AppStrings.taskDayThursday,
      AppStrings.taskDayFriday,
      AppStrings.taskDaySaturday,
      AppStrings.taskDaySunday,
    ];
    final selectedDays =
        Set<int>.from(widget.task.recurrenceDaysOfWeek ?? <int>[]);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CupertinoActionSheet(
          title: const Text(AppStrings.taskRecurrenceWeeklyDaysLabel),
          actions: [
            for (var i = 0; i < 7; i++)
              CupertinoActionSheetAction(
                onPressed: () {
                  setModalState(() {
                    final day = i + 1;
                    if (selectedDays.contains(day)) {
                      selectedDays.remove(day);
                    } else {
                      selectedDays.add(day);
                    }
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dayNames[i]),
                    if (selectedDays.contains(i + 1)) ...[
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.checkmark, size: 16),
                    ],
                  ],
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              if (selectedDays.isNotEmpty) {
                final sorted = selectedDays.toList()..sort();
                _onFieldsChanged({'recurrenceDaysOfWeek': sorted.toString()});
              } else {
                // No days selected — revert recurrence rule
                _onFieldsChanged({
                  'recurrenceRule': null,
                  'recurrenceDaysOfWeek': null,
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.actionDone),
          ),
        ),
      ),
    );
  }

  void _showCustomIntervalPicker() {
    int selectedInterval = widget.task.recurrenceInterval ?? 2;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: Text(
                    AppStrings.taskRecurrenceCustomDaysLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                CupertinoButton(
                  child: const Text(AppStrings.actionDone),
                  onPressed: () {
                    _onFieldsChanged({'recurrenceInterval': selectedInterval});
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedInterval - 2,
                ),
                onSelectedItemChanged: (index) {
                  selectedInterval = index + 2;
                },
                children: List<Widget>.generate(
                  364,
                  (index) => Center(
                    child: Text('${index + 2}'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependenciesSection(BuildContext context, OnTaskColors colors) {
    final depsAsync =
        ref.watch(dependenciesProvider(taskId: widget.task.id));
    final dependsOn = depsAsync.value?.dependsOn ?? <TaskDependency>[];

    // Get all tasks in the same list to resolve names and for the picker
    final allTasks = ref
            .watch(tasksProvider(
              listId: widget.task.listId,
              sectionId: widget.task.sectionId,
            ))
            .value ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              CupertinoIcons.link,
              size: 18,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppStrings.taskDependenciesLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
        // Existing dependencies
        for (final dep in dependsOn)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xl,
              top: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _taskTitleById(allTasks, dep.dependsOnTaskId),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  onPressed: () {
                    ref
                        .read(dependenciesProvider(taskId: widget.task.id)
                            .notifier)
                        .removeDependency(dep.id);
                  },
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        // Add dependency button
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            top: AppSpacing.xs,
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 24,
            onPressed: () => _showDependencyPicker(allTasks, dependsOn),
            child: Text(
              AppStrings.taskAddDependency,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.accentPrimary,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  String _taskTitleById(List<Task> tasks, String taskId) {
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    return task?.title ?? taskId;
  }

  void _showDependencyPicker(
    List<Task> allTasks,
    List<TaskDependency> existingDeps,
  ) {
    final existingIds = existingDeps.map((d) => d.dependsOnTaskId).toSet();
    final available = allTasks
        .where((t) => t.id != widget.task.id && !existingIds.contains(t.id))
        .toList();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => DependencyPicker(
        availableTasks: available,
        onSelected: (task) {
          Navigator.of(context).pop();
          ref
              .read(
                  dependenciesProvider(taskId: widget.task.id).notifier)
              .addDependency(task.id);
        },
      ),
    );
  }

  String _recurrenceLabel(RecurrenceRule rule) {
    switch (rule) {
      case RecurrenceRule.daily:
        return AppStrings.taskRecurrenceDaily;
      case RecurrenceRule.weekly:
        return AppStrings.taskRecurrenceWeekly;
      case RecurrenceRule.monthly:
        return AppStrings.taskRecurrenceMonthly;
      case RecurrenceRule.custom:
        if (widget.task.recurrenceInterval != null) {
          return AppStrings.taskRecurrenceEveryNDays.replaceAll('{n}', '${widget.task.recurrenceInterval}');
        }
        return AppStrings.taskRecurrenceCustom;
    }
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
          const SizedBox(height: AppSpacing.md),

          // Recurrence picker
          GestureDetector(
            onTap: _showRecurrencePicker,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.repeat,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.task.recurrenceRule != null
                      ? '${AppStrings.taskRecurrenceLabel}: ${_recurrenceLabel(widget.task.recurrenceRule!)}'
                      : AppStrings.taskRecurrenceLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Dependencies section
          _buildDependenciesSection(context, colors),
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
