import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../lists/domain/task_list.dart';
import '../../lists/presentation/lists_provider.dart';
import '../../tasks/domain/energy_requirement.dart';
import '../../tasks/domain/recurrence_rule.dart';
import '../../tasks/domain/task_priority.dart';
import '../../tasks/domain/time_window.dart';
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
  TimeWindow? _timeWindow;
  String? _timeWindowStart;
  String? _timeWindowEnd;
  EnergyRequirement? _energyRequirement;
  TaskPriority? _priority;
  RecurrenceRule? _recurrenceRule;
  int? _recurrenceInterval;
  List<int>? _recurrenceDaysOfWeek;
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
            timeWindow: _timeWindow?.toJson(),
            timeWindowStart: _timeWindow == TimeWindow.custom ? _timeWindowStart : null,
            timeWindowEnd: _timeWindow == TimeWindow.custom ? _timeWindowEnd : null,
            energyRequirement: _energyRequirement?.toJson(),
            priority: _priority?.toJson(),
            recurrenceRule: _recurrenceRule?.toJson(),
            recurrenceInterval: _recurrenceInterval,
            recurrenceDaysOfWeek: _recurrenceDaysOfWeek != null
                ? _recurrenceDaysOfWeek.toString()
                : null,
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
                  child: const Text(AppStrings.actionDone),
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
            child: const Text(AppStrings.actionNone),
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
          child: const Text(AppStrings.actionCancel),
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
              setState(() {
                _timeWindow = null;
                _timeWindowStart = null;
                _timeWindowEnd = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.actionNone),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _timeWindow = TimeWindow.morning);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskTimeWindowMorning),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _timeWindow = TimeWindow.afternoon);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskTimeWindowAfternoon),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _timeWindow = TimeWindow.evening);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskTimeWindowEvening),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _timeWindow = TimeWindow.custom);
              Navigator.of(context).pop();
              _showCustomTimeRangePicker();
            },
            child: const Text(AppStrings.taskTimeWindowCustom),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  void _showCustomTimeRangePicker() {
    DateTime startTime = DateTime(2026, 1, 1, 9, 0);
    DateTime endTime = DateTime(2026, 1, 1, 11, 0);

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
                    setState(() {
                      _timeWindowStart =
                          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                      _timeWindowEnd =
                          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
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

  void _showEnergyPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.taskEnergyLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _energyRequirement = null);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.actionNone),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _energyRequirement = EnergyRequirement.highFocus);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskEnergyHighFocus),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _energyRequirement = EnergyRequirement.lowEnergy);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskEnergyLowEnergy),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _energyRequirement = EnergyRequirement.flexible);
              Navigator.of(context).pop();
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
              setState(() => _priority = null);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskPriorityNormal),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _priority = TaskPriority.high);
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskPriorityHigh),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _priority = TaskPriority.critical);
              Navigator.of(context).pop();
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
              setState(() {
                _recurrenceRule = null;
                _recurrenceInterval = null;
                _recurrenceDaysOfWeek = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.actionNone),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _recurrenceRule = RecurrenceRule.daily;
                _recurrenceInterval = null;
                _recurrenceDaysOfWeek = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskRecurrenceDaily),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _recurrenceRule = RecurrenceRule.weekly;
                _recurrenceInterval = null;
              });
              Navigator.of(context).pop();
              _showWeeklyDayPicker();
            },
            child: const Text(AppStrings.taskRecurrenceWeekly),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _recurrenceRule = RecurrenceRule.monthly;
                _recurrenceInterval = null;
                _recurrenceDaysOfWeek = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.taskRecurrenceMonthly),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _recurrenceRule = RecurrenceRule.custom;
                _recurrenceDaysOfWeek = null;
              });
              Navigator.of(context).pop();
              _showCustomIntervalPicker();
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
    // ISO day numbers: Mon=1..Sun=7
    final selectedDays = Set<int>.from(_recurrenceDaysOfWeek ?? <int>[]);

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
                setState(() {
                  _recurrenceDaysOfWeek = selectedDays.toList()..sort();
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
    int selectedInterval = _recurrenceInterval ?? 2;

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
                    setState(() {
                      _recurrenceInterval = selectedInterval;
                    });
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
                  364, // 2..365
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

  String _recurrenceDisplayLabel() {
    if (_recurrenceRule == null) return AppStrings.taskRecurrenceLabel;
    switch (_recurrenceRule!) {
      case RecurrenceRule.daily:
        return '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceDaily}';
      case RecurrenceRule.weekly:
        return '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceWeekly}';
      case RecurrenceRule.monthly:
        return '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceMonthly}';
      case RecurrenceRule.custom:
        if (_recurrenceInterval != null) {
          return '${AppStrings.taskRecurrenceLabel}: Every ${_recurrenceInterval} days';
        }
        return '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceCustom}';
    }
  }

  String _timeWindowDisplayLabel() {
    if (_timeWindow == null) return AppStrings.taskTimeWindowLabel;
    switch (_timeWindow!) {
      case TimeWindow.morning:
        return '${AppStrings.taskTimeWindowLabel}: ${AppStrings.taskTimeWindowMorning}';
      case TimeWindow.afternoon:
        return '${AppStrings.taskTimeWindowLabel}: ${AppStrings.taskTimeWindowAfternoon}';
      case TimeWindow.evening:
        return '${AppStrings.taskTimeWindowLabel}: ${AppStrings.taskTimeWindowEvening}';
      case TimeWindow.custom:
        if (_timeWindowStart != null && _timeWindowEnd != null) {
          return '${AppStrings.taskTimeWindowLabel}: $_timeWindowStart – $_timeWindowEnd';
        }
        return '${AppStrings.taskTimeWindowLabel}: ${AppStrings.taskTimeWindowCustom}';
    }
  }

  String _energyDisplayLabel() {
    if (_energyRequirement == null) return AppStrings.taskEnergyLabel;
    switch (_energyRequirement!) {
      case EnergyRequirement.highFocus:
        return '${AppStrings.taskEnergyLabel}: ${AppStrings.taskEnergyHighFocus}';
      case EnergyRequirement.lowEnergy:
        return '${AppStrings.taskEnergyLabel}: ${AppStrings.taskEnergyLowEnergy}';
      case EnergyRequirement.flexible:
        return '${AppStrings.taskEnergyLabel}: ${AppStrings.taskEnergyFlexible}';
    }
  }

  String _priorityDisplayLabel() {
    if (_priority == null) return AppStrings.taskPriorityLabel;
    switch (_priority!) {
      case TaskPriority.normal:
        return '${AppStrings.taskPriorityLabel}: ${AppStrings.taskPriorityNormal}';
      case TaskPriority.high:
        return '${AppStrings.taskPriorityLabel}: ${AppStrings.taskPriorityHigh}';
      case TaskPriority.critical:
        return '${AppStrings.taskPriorityLabel}: ${AppStrings.taskPriorityCritical}';
    }
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
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Time window picker
                GestureDetector(
                  onTap: _showTimeWindowPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _timeWindowDisplayLabel(),
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

                // Energy requirement picker
                GestureDetector(
                  onTap: _showEnergyPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.bolt,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _energyDisplayLabel(),
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

                // Priority picker
                GestureDetector(
                  onTap: _showPriorityPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.flag,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _priorityDisplayLabel(),
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

                // Recurrence picker
                GestureDetector(
                  onTap: _showRecurrencePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.repeat,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _recurrenceDisplayLabel(),
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

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _isSubmitting ? null : _createTask,
                    child: Text(
                      _isSubmitting ? AppStrings.submittingIndicator : AppStrings.addTaskCreateButton,
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
