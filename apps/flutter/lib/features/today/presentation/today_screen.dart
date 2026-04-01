import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show AnimatedCrossFade, Colors, CrossFadeState, Theme, showModalBottomSheet;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/shell/presentation/shell_providers.dart';
import '../../scheduling/presentation/widgets/nudge_input_sheet.dart';
import '../../tasks/domain/task.dart';
import '../domain/day_health.dart';
import 'schedule_change_provider.dart';
import 'schedule_health_provider.dart';
import 'today_provider.dart';
import 'today_view_mode_provider.dart';
import '../data/calendar_event_dto.dart';
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

  /// Whether "The reveal" animation has already played this session.
  ///
  /// Set to true after the first transition from loading → data, so the
  /// staggered appearance only plays once per session (not on every rebuild).
  bool _hasPlayedReveal = false;

  /// Task IDs that have changed in the latest schedule update.
  ///
  /// Populated when [scheduleChangeBannerVisibleProvider] becomes true, then
  /// cleared after the "plan shifts" animation completes.
  Set<String> _changedTaskIds = {};

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
    final calendarEventsState = ref.watch(todayCalendarEventsProvider);
    final calendarEvents = calendarEventsState.value ?? <CalendarEventDto>[];

    // Listen for banner visibility → start/cancel 8-second auto-dismiss timer
    // and capture changed task IDs for "The plan shifts" animation (UX-DR20).
    ref.listen<AsyncValue<bool>>(scheduleChangeBannerVisibleProvider,
        (previous, next) {
      if (next.value == true) {
        _autoDismissTimer?.cancel();
        _autoDismissTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) {
            ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss();
          }
        });

        // Capture changed task IDs so animated rows can identify themselves
        final changesAsync = ref.read(scheduleChangesProvider);
        changesAsync.whenData((changes) {
          if (mounted) {
            setState(() {
              _changedTaskIds = changes.changes.map((c) => c.taskId).toSet();
            });
            // Clear the set after the animation duration so it doesn't persist
            Future.delayed(
              Duration(milliseconds: MotionTokens.planShiftsDurationMs + 100),
              () {
                if (mounted) {
                  setState(() => _changedTaskIds = {});
                }
              },
            );
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
                    // Mark reveal as played after first data render
                    final playReveal = !_hasPlayedReveal;
                    if (playReveal) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_hasPlayedReveal) {
                          setState(() => _hasPlayedReveal = true);
                        }
                      });
                    }

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
                          playReveal: playReveal,
                          changedTaskIds: _changedTaskIds,
                          onComplete: (id) =>
                              ref.read(todayProvider.notifier).completeTask(id),
                          onReschedule: (id) =>
                              _showReschedulePicker(context, id),
                          onNudge: (id, title) =>
                              _showNudgeSheet(context, id, title),
                        ),
                      ),
                      secondChild: SizedBox(
                        height: constraints.maxHeight,
                        child: TimelineView(
                          tasks: tasks,
                          calendarBlocks: calendarEvents,
                        ),
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

  void _showNudgeSheet(BuildContext context, String taskId, String taskTitle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NudgeInputSheet(
        taskId: taskId,
        taskTitle: taskTitle,
        onApplied: () => ref.read(todayProvider.notifier).refresh(),
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
  final void Function(String taskId, String taskTitle) onNudge;

  /// Whether "The reveal" stagger animation should play this build.
  final bool playReveal;

  /// Task IDs that changed in the latest schedule update.
  ///
  /// Rows whose [Task.id] is in this set will play "The plan shifts" animation.
  final Set<String> changedTaskIds;

  const _TodayContent({
    required this.tasks,
    required this.healthDays,
    required this.onComplete,
    required this.onReschedule,
    required this.onNudge,
    required this.playReveal,
    required this.changedTaskIds,
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
            onNudge: onNudge,
            playReveal: playReveal,
            changedTaskIds: changedTaskIds,
          ),
        ],
        // Morning section
        if (morning.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayMorningSection),
          _TaskSliver(
            tasks: morning,
            onComplete: onComplete,
            onReschedule: onReschedule,
            onNudge: onNudge,
            playReveal: playReveal,
            changedTaskIds: changedTaskIds,
          ),
        ],
        // Afternoon section
        if (afternoon.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayAfternoonSection),
          _TaskSliver(
            tasks: afternoon,
            onComplete: onComplete,
            onReschedule: onReschedule,
            onNudge: onNudge,
            playReveal: playReveal,
            changedTaskIds: changedTaskIds,
          ),
        ],
        // Evening section
        if (evening.isNotEmpty) ...[
          _SectionDivider(title: AppStrings.todayEveningSection),
          _TaskSliver(
            tasks: evening,
            onComplete: onComplete,
            onReschedule: onReschedule,
            onNudge: onNudge,
            playReveal: playReveal,
            changedTaskIds: changedTaskIds,
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

/// Sliver list of [TodayTaskRow] widgets with motion token support.
///
/// Handles:
/// - "The reveal" (UX-DR20): staggered fade+slide on initial load
/// - "The plan shifts" (UX-DR20): colour flash on schedule-changed rows
/// - Reduce Motion: instant render when [MediaQuery.disableAnimations] is true
class _TaskSliver extends StatelessWidget {
  final List<Task> tasks;
  final TodayTaskRowState? rowState;
  final void Function(String) onComplete;
  final void Function(String) onReschedule;
  final void Function(String taskId, String taskTitle) onNudge;

  /// Whether to play "The reveal" stagger animation this build.
  final bool playReveal;

  /// Task IDs currently playing "The plan shifts" animation.
  final Set<String> changedTaskIds;

  const _TaskSliver({
    required this.tasks,
    this.rowState,
    required this.onComplete,
    required this.onReschedule,
    required this.onNudge,
    required this.playReveal,
    required this.changedTaskIds,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final task = tasks[index];
          final state = rowState ?? _determineState(task);
          final isChanged = changedTaskIds.contains(task.id);

          Widget row = TodayTaskRow(
            taskId: task.id,
            title: task.title,
            timeLabel: _formatTime(task.dueDate),
            listName: task.listName,
            rowState: state,
            onComplete: () => onComplete(task.id),
            onReschedule: () => onReschedule(task.id),
            onNudge: (state == TodayTaskRowState.upcoming ||
                    state == TodayTaskRowState.current)
                ? () => onNudge(task.id, task.title)
                : null,
          );

          // "The plan shifts" — colour flash on changed rows (UX-DR20)
          if (isChanged) {
            row = _PlanShiftsAnimation(child: row);
          }

          // "The reveal" — staggered fade+slide on initial load (UX-DR20)
          if (playReveal) {
            row = _RevealAnimation(index: index, child: row);
          }

          return row;
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

// ── "The reveal" animation — staggered fade + upward slide ───────────────────

/// Wraps a task row with "The reveal" animation: fade + slight upward slide
/// with a per-row stagger delay (UX-DR20).
///
/// Respects Reduce Motion via [MediaQuery.disableAnimations] —
/// when true, renders at full opacity immediately.
class _RevealAnimation extends StatefulWidget {
  final int index;
  final Widget child;

  const _RevealAnimation({required this.index, required this.child});

  @override
  State<_RevealAnimation> createState() => _RevealAnimationState();
}

class _RevealAnimationState extends State<_RevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: MotionTokens.revealDurationMs),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check disableAnimations in didChangeDependencies — not initState —
    // per the established pattern from ChapterBreakScreen (Story 2.13).
    if (!_animationStarted) {
      _animationStarted = true;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        _controller.value = 1.0; // instant — no animation
      } else {
        final stagger = Duration(
          milliseconds: widget.index * MotionTokens.revealStaggerMs,
        );
        Future.delayed(stagger, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ── "The plan shifts" animation — colour flash on changed rows ────────────────

/// Wraps a task row with "The plan shifts" animation: a quick background
/// colour flash that fades back over [MotionTokens.planShiftsDurationMs] (UX-DR20).
///
/// One-shot per schedule change event — does not loop.
/// Does NOT affect layout — uses [AnimatedContainer] background only.
/// Respects Reduce Motion via [MediaQuery.disableAnimations].
class _PlanShiftsAnimation extends StatefulWidget {
  final Widget child;

  const _PlanShiftsAnimation({required this.child});

  @override
  State<_PlanShiftsAnimation> createState() => _PlanShiftsAnimationState();
}

class _PlanShiftsAnimationState extends State<_PlanShiftsAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: MotionTokens.planShiftsDurationMs),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationStarted) {
      _animationStarted = true;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (!disableAnimations) {
        // Flash forward then reverse (pulse effect)
        _controller.forward().then((_) {
          if (mounted) _controller.reverse();
        });
      }
      // Reduce Motion: no animation — render at normal state immediately
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.transparent.withValues(
            alpha: 0,
          ),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              colors.accentPrimary.withValues(alpha: _controller.value * 0.2),
              BlendMode.srcOver,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
