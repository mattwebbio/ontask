import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show AnimatedCrossFade, CrossFadeState, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/shell/presentation/shell_providers.dart';
import '../../tasks/domain/task.dart';
import '../domain/day_health.dart';
import 'schedule_change_provider.dart';
import 'schedule_health_provider.dart';
import 'today_provider.dart';
import 'today_view_mode_provider.dart';
import 'widgets/overbooking_warning_banner.dart';
import 'widgets/schedule_change_banner.dart';
import 'widgets/schedule_health_strip.dart';
import 'widgets/timeline_view.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_skeleton.dart';
import 'widgets/today_task_row.dart';

/// Today tab showing tasks for the day with a weekly health indicator.
///
/// Watches [todayProvider] for task list and [scheduleHealthProvider] for
/// health strip data. Shows skeleton during loading (800ms hard cap),
/// then either empty state or task rows with schedule health strip.
///
/// The [TodayEmptyState] Add CTA is wired to [openAddSheetRequestProvider],
/// which [AppShell] watches to open [AddTabSheet]. The optional [onAddTapped]
/// parameter is retained for widget tests that need direct callback injection.
class TodayScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAddTapped;

  const TodayScreen({this.onAddTapped, super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final Future<void> _skeletonDelay;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _skeletonDelay = Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _handleAddTapped() {
    if (widget.onAddTapped != null) {
      widget.onAddTapped!();
    } else {
      ref.read(openAddSheetRequestProvider.notifier).increment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayState = ref.watch(todayProvider);
    final healthState = ref.watch(scheduleHealthProvider);
    final viewModeAsync = ref.watch(todayViewModeProvider);
    final viewMode = viewModeAsync.value ?? TodayViewMode.list;

    // Listen for banner visibility → start/cancel 8-second auto-dismiss timer
    ref.listen<AsyncValue<bool>>(scheduleChangeBannerVisibleProvider,
        (previous, next) {
      if (next.value == true) {
        _autoDismissTimer?.cancel();
        _autoDismissTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) {
            ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss();
          }
        });
      } else {
        _autoDismissTimer?.cancel();
      }
    });

    return SafeArea(
      child: FutureBuilder<void>(
        future: _skeletonDelay,
        builder: (context, snapshot) {
          final skeletonDone =
              snapshot.connectionState == ConnectionState.done;

          // Show skeleton while either: skeleton delay not done, or data loading
          if (!skeletonDone || todayState.isLoading) {
            return const TodaySkeleton();
          }

          // Error state: fall through to empty
          final tasks = todayState.value ?? [];

          if (tasks.isEmpty) {
            return TodayEmptyState(onAddTapped: _handleAddTapped);
          }

          final colors = Theme.of(context).extension<OnTaskColors>()!;
          final isTimeline = viewMode == TodayViewMode.timeline;

          return Column(
            children: [
              // Header with toggle button — renders above both views
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Text(
                      AppStrings.todayHeaderTitle,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppStrings.todayTaskCount
                          .replaceFirst('{count}', '${tasks.length}'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final newMode = isTimeline
                            ? TodayViewMode.list
                            : TodayViewMode.timeline;
                        ref
                            .read(todayViewModeSettingsProvider.notifier)
                            .setViewMode(newMode);
                      },
                      child: Semantics(
                        label: isTimeline
                            ? AppStrings.timelineToggleToList
                            : AppStrings.timelineToggleToTimeline,
                        child: Icon(
                          isTimeline
                              ? CupertinoIcons.list_bullet
                              : CupertinoIcons.calendar,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // AnimatedCrossFade between list and timeline views
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: isTimeline
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: SizedBox(
                        height: constraints.maxHeight,
                        child: _TodayContent(
                          tasks: tasks,
                          healthDays: healthState.value ?? [],
                          onComplete: (id) =>
                              ref.read(todayProvider.notifier).completeTask(id),
                          onReschedule: (id) =>
                              _showReschedulePicker(context, id),
                        ),
                      ),
                      secondChild: SizedBox(
                        height: constraints.maxHeight,
                        child: TimelineView(tasks: tasks),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReschedulePicker(BuildContext context, String taskId) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text(AppStrings.actionCancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  AppStrings.todayReschedulePickerTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                CupertinoButton(
                  child: const Text(AppStrings.actionDone),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(todayProvider.notifier)
                        .rescheduleTask(
                          taskId,
                          selectedDate.toIso8601String(),
                        );
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                minimumDate: DateTime.now(),
                onDateTimeChanged: (date) => selectedDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main content widget for when tasks are loaded.
class _TodayContent extends StatelessWidget {
  final List<Task> tasks;
  final List<DayHealth> healthDays;
  final void Function(String) onComplete;
  final void Function(String) onReschedule;

  const _TodayContent({
    required this.tasks,
    required this.healthDays,
    required this.onComplete,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Group tasks by time of day
    final overdue = <Task>[];
    final morning = <Task>[];
    final afternoon = <Task>[];
    final evening = <Task>[];

    for (final task in tasks) {
      if (task.completedAt != null) {
        // Completed tasks go into their original time block
        _addToTimeBlock(task, morning, afternoon, evening);
        continue;
      }
      if (task.dueDate != null && task.dueDate!.isBefore(now)) {
        overdue.add(task);
        continue;
      }
      _addToTimeBlock(task, morning, afternoon, evening);
    }

    return CustomScrollView(
      slivers: [
        // Schedule Change Banner — always included (hides itself via SizedBox.shrink)
        const SliverToBoxAdapter(
          child: ScheduleChangeBannerAsync(),
        ),
        // Overbooking Warning Banner — always included (hides itself via SizedBox.shrink)
        const SliverToBoxAdapter(
          child: OverbookingWarningBannerAsync(),
        ),
        // Schedule health strip
        if (healthDays.isNotEmpty)
          SliverToBoxAdapter(
            child: ScheduleHealthStrip(days: healthDays),
          ),
        // Overdue section
        if (overdue.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayOverdueSection),
          _TaskSliver(
            tasks: overdue,
            rowState: TodayTaskRowState.overdue,
            onComplete: onComplete,
            onReschedule: onReschedule,
          ),
        ],
        // Morning section
        if (morning.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayMorningSection),
          _TaskSliver(
            tasks: morning,
            onComplete: onComplete,
            onReschedule: onReschedule,
          ),
        ],
        // Afternoon section
        if (afternoon.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayAfternoonSection),
          _TaskSliver(
            tasks: afternoon,
            onComplete: onComplete,
            onReschedule: onReschedule,
          ),
        ],
        // Evening section
        if (evening.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayEveningSection),
          _TaskSliver(
            tasks: evening,
            onComplete: onComplete,
            onReschedule: onReschedule,
          ),
        ],
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxxl),
        ),
      ],
    );
  }

  void _addToTimeBlock(
    Task task,
    List<Task> morning,
    List<Task> afternoon,
    List<Task> evening,
  ) {
    final hour = task.dueDate?.hour ?? 9; // Default to morning
    if (hour < 12) {
      morning.add(task);
    } else if (hour < 17) {
      afternoon.add(task);
    } else {
      evening.add(task);
    }
  }
}

/// Lightweight section divider for time-of-day grouping.
class _SectionDivider extends StatelessWidget {
  final String title;

  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ),
    );
  }
}

/// Sliver list of [TodayTaskRow] widgets.
class _TaskSliver extends StatelessWidget {
  final List<Task> tasks;
  final TodayTaskRowState? rowState;
  final void Function(String) onComplete;
  final void Function(String) onReschedule;

  const _TaskSliver({
    required this.tasks,
    this.rowState,
    required this.onComplete,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final task = tasks[index];
          return TodayTaskRow(
            taskId: task.id,
            title: task.title,
            timeLabel: _formatTime(task.dueDate),
            rowState: rowState ?? _determineState(task),
            onComplete: () => onComplete(task.id),
            onReschedule: () => onReschedule(task.id),
          );
        },
        childCount: tasks.length,
      ),
    );
  }

  TodayTaskRowState _determineState(Task task) {
    if (task.completedAt != null) return TodayTaskRowState.completed;
    final now = DateTime.now();
    if (task.dueDate != null && task.dueDate!.isBefore(now)) {
      return TodayTaskRowState.overdue;
    }
    // TODO(stub): calendarEvent and current detection require real scheduling data
    return TodayTaskRowState.upcoming;
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? AppStrings.todayTimePm : AppStrings.todayTimeAm;
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    if (minute == 0) return '$displayHour$period';
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }
}
