import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/fixtures/demo_schedule.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// The emotional hook screen — the first thing a new user sees.
///
/// Displays a pre-populated sample schedule sourced from [kDemoSchedule]
/// (a pure static fixture — no API call, no Riverpod).  The welcome headline
/// uses New York serif (the "emotional voice layer", UX-DR32).  All other copy
/// uses SF Pro (system font).
///
/// No calendar permission or any system permission is requested before this
/// screen is seen (AC #1).
class SampleScheduleStep extends StatelessWidget {
  const SampleScheduleStep({
    required this.onNext,
    required this.onSkipAll,
    super.key,
  });

  /// Called when the primary CTA "Let's set it up" is tapped.
  final VoidCallback onNext;

  /// Called when the secondary CTA "Skip setup — take me to the app" is tapped.
  final VoidCallback onSkipAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    // Resolve serif family from theme — same pattern as NowEmptyState
    final serifFamily = Theme.of(context).textTheme.displayLarge?.fontFamily;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Welcome headline — New York serif (emotional voice layer, UX-DR32)
              Text(
                AppStrings.onboardingWelcomeHeadline,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontFamily: serifFamily,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Demo task list — no API call, loads from static fixture
              Expanded(
                child: ListView.separated(
                  itemCount: kDemoSchedule.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final task = kDemoSchedule[index];
                    return _DemoTaskCard(task: task, colors: colors);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Primary CTA — SF Pro
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: onNext,
                  child: Text(AppStrings.onboardingLetSetItUp),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Secondary CTA — "Skip setup" text button — SF Pro
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: onSkipAll,
                  child: Text(
                    AppStrings.onboardingSkipAll,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single demo task card rendered in the onboarding sample schedule.
///
/// Completed tasks are rendered at reduced opacity with a strikethrough title
/// to demonstrate the "done" visual state — matching the visual language
/// established in the Now tab (UX-DR27).
class _DemoTaskCard extends StatelessWidget {
  const _DemoTaskCard({required this.task, required this.colors});

  final DemoTask task;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${task.scheduledTime.hour.toString().padLeft(2, '0')}:${task.scheduledTime.minute.toString().padLeft(2, '0')}';
    final durationString = '${task.durationMinutes} min';

    return Opacity(
      opacity: task.isCompleted ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Completion indicator
            Icon(
              task.isCompleted
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: task.isCompleted ? colors.accentCompletion : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Task title and metadata — SF Pro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: colors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeString · $durationString',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
