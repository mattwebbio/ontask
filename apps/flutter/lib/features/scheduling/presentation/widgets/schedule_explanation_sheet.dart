import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../schedule_explanation_provider.dart';

/// Bottom sheet displayed when the user taps "Why here?" on a task row.
///
/// Shows a plain-language explanation of why the task was placed at its
/// scheduled time (FR13). Designed as a standard iOS informational bottom
/// sheet — swipe-down to dismiss.
///
/// States:
/// - Loading: [CupertinoActivityIndicator] centred
/// - Error: plain-language message (NFR-UX2)
/// - Success: [ListView] of reason strings
class ScheduleExplanationSheet extends ConsumerWidget {
  final String taskId;

  const ScheduleExplanationSheet({
    required this.taskId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final explanationAsync = ref.watch(scheduleExplanationProvider(taskId));

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      // Minimum height; expands with content
      constraints: const BoxConstraints(minHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sheet handle ─────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Title ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              'Why here?',
              style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
          // ── Content ──────────────────────────────────────────────────────
          explanationAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                "Couldn't load explanation. Try again.",
                style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
              ),
            ),
            data: (explanation) {
              if (explanation.reasons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Text(
                    'No explanation available for this task.',
                    style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                itemCount: explanation.reasons.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      explanation.reasons[index],
                      style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
