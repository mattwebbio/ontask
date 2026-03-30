import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Skeleton loading placeholder for the Now tab hero card area.
///
/// Renders a card-proportioned skeleton (~160pt height) with the same shimmer
/// animation as [TodaySkeleton] (1.2s loop). Wrapped in [RepaintBoundary].
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
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      height: 160,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
    );
  }
}
