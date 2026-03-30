import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Empty state for the Now tab when there is no current task.
///
/// Uses New York serif font (resolved from the theme's displayLarge fontFamily),
/// centred layout, `color.text.secondary` — no illustration. Emptiness is
/// intentional: negative space communicates calm.
///
/// [nextTaskHint] is shown when the next scheduled task is known
/// (e.g. "Budget review at 2pm"). Pass null to omit the hint.
class NowEmptyState extends StatelessWidget {
  final String? nextTaskHint;

  const NowEmptyState({this.nextTaskHint, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    // Resolve serif family from theme — same one wired in main.dart
    final serifFamily = Theme.of(context).textTheme.displayLarge?.fontFamily;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.nowEmptyTitle,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontFamily: serifFamily,
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (nextTaskHint != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Next: $nextTaskHint',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
