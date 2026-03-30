import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Empty state for the Today tab when no tasks are scheduled.
///
/// Uses SF Pro 17pt (system font via Theme), not celebratory. Single CTA
/// triggers the Add sheet via [onAddTapped] callback. Do NOT use go_router
/// directly from this empty state.
class TodayEmptyState extends StatelessWidget {
  final VoidCallback onAddTapped;

  const TodayEmptyState({required this.onAddTapped, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.todayEmptyTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onAddTapped,
              child: Text(
                AppStrings.todayEmptyAddCta,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.accentPrimary,
                      decoration: TextDecoration.underline,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
