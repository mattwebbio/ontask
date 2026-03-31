import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Skeleton loading placeholder for the Now tab hero card area.
///
/// Renders a card-proportioned skeleton matching [NowTaskCard] layout:
/// title area (28pt height placeholder) + attribution line + metadata row + CTA area.
///
/// Uses the same shimmer animation as [TodaySkeleton] (1.2s loop). Wrapped in
/// [RepaintBoundary].
///
/// Reduced-motion: when [MediaQuery.disableAnimations] is true, renders a
/// static fill with no shimmer animation.
class NowCardSkeleton extends StatelessWidget {
  const NowCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    // Reduced motion: skip shimmer animation
    if (MediaQuery.of(context).disableAnimations) {
      return _buildCard(colors);
    }

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.surfaceSecondary,
        highlightColor: colors.surfacePrimary,
        period: const Duration(milliseconds: 1200),
        child: _buildCard(colors),
      ),
    );
  }

  Widget _buildCard(OnTaskColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Attribution placeholder
              Container(
                width: 200,
                height: 15,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Title placeholder (28pt height)
              Container(
                width: 240,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Metadata row placeholder
              Container(
                width: 140,
                height: 15,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // CTA placeholder
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
