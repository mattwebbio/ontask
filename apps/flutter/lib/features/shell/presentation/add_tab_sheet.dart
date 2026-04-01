import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../lists/domain/task_list.dart';
import '../../lists/presentation/lists_provider.dart';
import '../../tasks/domain/energy_requirement.dart';
import '../../tasks/domain/recurrence_rule.dart';
import '../../tasks/domain/task_priority.dart';
import '../../tasks/domain/time_window.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../data/nlp_task_repository.dart';
import '../domain/task_parse_result.dart';
import 'guided_chat_sheet.dart';

/// Add mode toggle — Quick Capture (NLP default), Guided Chat, or Form.
enum _AddMode { quickCapture, guided, form }

/// Modal sheet shown when the Add action tab is tapped.
///
/// Opened by [AppShell] via [showModalBottomSheet] — this is NOT a persistent
/// navigation destination. The Add tab is an action tab, not a content tab.
///
/// Story 4.1: Upgraded to support Quick Capture NLP mode (FR1b).
/// Default mode is Quick Capture. Form mode preserves all existing fields.
class AddTabSheet extends ConsumerStatefulWidget {
  const AddTabSheet({super.key});

  @override
  ConsumerState<AddTabSheet> createState() => _AddTabSheetState();
}

class _AddTabSheetState extends ConsumerState<AddTabSheet> {
  // ── Form mode state ──────────────────────────────────────────────────────
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

  // ── NLP Quick Capture state ──────────────────────────────────────────────
  _AddMode _mode = _AddMode.quickCapture;
  final _nlpController = TextEditingController();
  Timer? _debounceTimer;
  bool _isParsingNlp = false;
  TaskParseResult? _parsedResult;
  bool _nlpLowConfidence = false;
  bool _nlpError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _nlpController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── NLP parsing logic ────────────────────────────────────────────────────

  void _onNlpInputChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _parsedResult = null;
        _nlpLowConfidence = false;
        _nlpError = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _callNlpParse(value);
    });
  }

  Future<void> _callNlpParse(String utterance) async {
    if (!mounted) return;
    setState(() {
      _isParsingNlp = true;
      _nlpLowConfidence = false;
      _nlpError = false;
      _parsedResult = null;
    });

    try {
      final repo = ref.read(nlpTaskRepositoryProvider);
      final result = await repo.parseUtterance(utterance);
      if (!mounted) return;

      if (result.confidence == 'low') {
        setState(() {
          _isParsingNlp = false;
          _nlpLowConfidence = true;
          _parsedResult = null;
        });
        return;
      }

      setState(() {
        _isParsingNlp = false;
        _parsedResult = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isParsingNlp = false;
        _nlpError = true;
        _parsedResult = null;
      });
    }
  }

  Future<void> _createTaskFromNlp() async {
    final result = _parsedResult;
    final title = result?.title ?? _nlpController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(tasksProvider(listId: result?.listId).notifier)
          .createTask(
            title: title,
            dueDate: result?.dueDate,
            listId: result?.listId,
            energyRequirement: result?.energyRequirement,
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
            recurrenceDaysOfWeek: _recurrenceDaysOfWeek?.toString(),
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
              setState(() {
                if (selectedDays.isNotEmpty) {
                  _recurrenceDaysOfWeek = selectedDays.toList()..sort();
                } else {
                  // No days selected — revert recurrence rule
                  _recurrenceRule = null;
                  _recurrenceDaysOfWeek = null;
                }
              });
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
          return '${AppStrings.taskRecurrenceLabel}: ${AppStrings.taskRecurrenceEveryNDays.replaceAll('{n}', '$_recurrenceInterval')}';
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

                // ── Mode toggle row (3-way) ─────────────────────────────
                Row(
                  children: [
                    // Quick Capture segment (left)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = _AddMode.quickCapture),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _mode == _AddMode.quickCapture
                                ? colors.surfaceSecondary
                                : colors.surfacePrimary,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(AppSpacing.sm),
                            ),
                            border: Border.all(color: colors.surfaceSecondary),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.sparkles, size: 14, color: colors.textSecondary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                AppStrings.addTaskModeQuickCapture,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Guided segment (middle)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Close AddTabSheet and open GuidedChatSheet as a separate modal.
                          // Capture the root navigator before popping — context is invalid
                          // once this widget is disposed (after pop).
                          final rootNavigator = Navigator.of(context, rootNavigator: true);
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showModalBottomSheet<void>(
                              context: rootNavigator.context,
                              isScrollControlled: true,
                              useRootNavigator: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const GuidedChatSheet(),
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _mode == _AddMode.guided
                                ? colors.surfaceSecondary
                                : colors.surfacePrimary,
                            border: Border.all(color: colors.surfaceSecondary),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.chat_bubble_text, size: 14, color: colors.textSecondary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                AppStrings.addTaskModeGuided,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Form segment (right)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _mode = _AddMode.form;
                            // Pre-fill title from NLP-resolved title if available
                            if (_parsedResult != null && _titleController.text.isEmpty) {
                              _titleController.text = _parsedResult!.title;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _mode == _AddMode.form
                                ? colors.surfaceSecondary
                                : colors.surfacePrimary,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(AppSpacing.sm),
                            ),
                            border: Border.all(color: colors.surfaceSecondary),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.square_grid_2x2, size: 14, color: colors.textSecondary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                AppStrings.addTaskModeForm,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Quick Capture mode ──────────────────────────────────
                if (_mode == _AddMode.quickCapture) ...[
                  CupertinoTextField(
                    controller: _nlpController,
                    placeholder: AppStrings.addTaskNlpPlaceholder,
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                    onChanged: _onNlpInputChanged,
                    onSubmitted: (v) {
                      _debounceTimer?.cancel();
                      if (v.trim().isNotEmpty) _callNlpParse(v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Loading state
                  if (_isParsingNlp) ...[
                    const Center(child: CupertinoActivityIndicator()),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Low confidence warning
                  if (_nlpLowConfidence) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.addTaskNlpLowConfidence,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Error state
                  if (_nlpError) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.addTaskNlpError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CupertinoColors.destructiveRed,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Parsed field pills
                  if (_parsedResult != null) ...[
                    _ParsedFieldPillRow(
                      result: _parsedResult!,
                      onTapTitle: null,
                      onTapDueDate: _showDatePicker,
                      onTapList: lists.isNotEmpty ? () => _showListPicker(lists) : null,
                      onTapTime: _showTimeWindowPicker,
                      onTapEnergy: _showEnergyPicker,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],

                // ── Form mode ───────────────────────────────────────────
                if (_mode == _AddMode.form) ...[
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
                ], // end Form mode

                // ── Submit button (Quick Capture and Form modes only) ───
                // Not shown in Guided mode — task creation happens in GuidedChatSheet.
                if (_mode != _AddMode.guided)
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isSubmitting
                          ? null
                          : (_mode == _AddMode.quickCapture
                              ? _createTaskFromNlp
                              : _createTask),
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

// ── _ParsedFieldPillRow ───────────────────────────────────────────────────────

/// Displays parsed task fields as labelled pills with staggered fade-in.
///
/// Respects Reduce Motion — skips stagger when [MediaQuery.disableAnimations].
class _ParsedFieldPillRow extends StatelessWidget {
  final TaskParseResult result;
  final VoidCallback? onTapTitle;
  final VoidCallback? onTapDueDate;
  final VoidCallback? onTapList;
  final VoidCallback? onTapTime;
  final VoidCallback? onTapEnergy;

  const _ParsedFieldPillRow({
    required this.result,
    this.onTapTitle,
    this.onTapDueDate,
    this.onTapList,
    this.onTapTime,
    this.onTapEnergy,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = isReducedMotion(context);

    final pills = <Widget>[];

    // Title pill (always shown)
    pills.add(_ParsedFieldPill(
      label: AppStrings.addTaskNlpTitle,
      value: result.title,
      confidence: result.fieldConfidences['title'] ?? 'high',
      onTap: onTapTitle,
    ));

    if (result.dueDate != null) {
      final date = DateTime.tryParse(result.dueDate!);
      pills.add(_ParsedFieldPill(
        label: AppStrings.addTaskNlpDueDate,
        value: date != null
            ? '${date.month}/${date.day}/${date.year}'
            : result.dueDate!,
        confidence: result.fieldConfidences['dueDate'] ?? 'high',
        onTap: onTapDueDate,
      ));
    }

    if (result.estimatedDurationMinutes != null) {
      pills.add(_ParsedFieldPill(
        label: AppStrings.addTaskNlpDuration,
        value: '${result.estimatedDurationMinutes}min',
        confidence: result.fieldConfidences['estimatedDurationMinutes'] ?? 'high',
        onTap: null,
      ));
    }

    if (result.energyRequirement != null) {
      pills.add(_ParsedFieldPill(
        label: AppStrings.addTaskNlpEnergy,
        value: result.energyRequirement!.replaceAll('_', ' '),
        confidence: result.fieldConfidences['energyRequirement'] ?? 'high',
        onTap: onTapEnergy,
      ));
    }

    if (result.listId != null) {
      pills.add(_ParsedFieldPill(
        label: AppStrings.addTaskNlpList,
        value: result.listId!,
        confidence: result.fieldConfidences['listId'] ?? 'high',
        onTap: onTapList,
      ));
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (int i = 0; i < pills.length; i++)
          reduced
              ? pills[i]
              : _StaggeredFadePill(
                  index: i,
                  child: pills[i],
                ),
      ],
    );
  }
}

// ── _StaggeredFadePill ────────────────────────────────────────────────────────

/// Wraps a pill with a staggered fade-in animation (UX-DR29, 150ms per step).
class _StaggeredFadePill extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadePill({required this.index, required this.child});

  @override
  State<_StaggeredFadePill> createState() => _StaggeredFadePillState();
}

class _StaggeredFadePillState extends State<_StaggeredFadePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: MotionTokens.revealDurationMs),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final delay = Duration(milliseconds: widget.index * 150);
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

// ── _ParsedFieldPill ──────────────────────────────────────────────────────────

/// A labelled pill showing a single parsed field from NLP task capture.
///
/// High-confidence: solid border with [colors.surfaceSecondary] background.
/// Low-confidence: same background but dashed border (1pt, [colors.textSecondary] at 60%).
///
/// Tapping the pill opens the corresponding field picker.
class _ParsedFieldPill extends StatelessWidget {
  final String label;
  final String value;
  final String confidence; // 'high' | 'low'
  final VoidCallback? onTap;

  const _ParsedFieldPill({
    required this.label,
    required this.value,
    required this.confidence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final isLow = confidence == 'low';

    return GestureDetector(
      onTap: onTap,
      child: isLow
          ? CustomPaint(
              painter: _DashedBorderPainter(
                color: colors.textSecondary.withAlpha(153), // 60% opacity
                borderRadius: 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _PillContent(label: label, value: value, colors: colors),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.surfaceSecondary),
              ),
              child: _PillContent(label: label, value: value, colors: colors),
            ),
    );
  }
}

class _PillContent extends StatelessWidget {
  final String label;
  final String value;
  final OnTaskColors colors;

  const _PillContent({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, fontFamily: 'SFPro'),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: colors.textSecondary),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DashedBorderPainter ──────────────────────────────────────────────────────

/// CustomPainter that draws a dashed rounded-rectangle border.
///
/// Used for low-confidence parsed field pills (UX-DR29).
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  static const double _dashWidth = 4;
  static const double _dashGap = 3;
  static const double _strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Convert rounded rect to a path and dash it
    final path = Path()..addRRect(rrect);
    _drawDashedPath(canvas, paint, path);
  }

  void _drawDashedPath(Canvas canvas, Paint paint, Path path) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + _dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
