import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Skeleton loading placeholder for the Today tab.
///
/// Shows a skeleton pill for the schedule health strip area at top,
/// followed by 4 skeleton task rows matching [TodayTaskRow] proportions
/// (40pt time label + title area + trailing indicator) with a shimmer
/// sweep animation (1.2s loop, left-to-right gradient).
///
/// Wrapped in [RepaintBoundary] to isolate repaints.
/// Reduced-motion: when [MediaQuery.disableAnimations] is true, renders a
/// static fill with no shimmer animation.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    // Reduced motion: skip shimmer animation
    if (MediaQuery.of(context).disableAnimations) {
      return _buildSkeletonContent(colors);
    }

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.surfaceSecondary,
        highlightColor: colors.surfacePrimary,
        period: const Duration(milliseconds: 1200),
        child: _buildSkeletonContent(colors),
      ),
    );
  }

  Widget _buildSkeletonContent(OnTaskColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule health strip skeleton
        _SkeletonHealthStrip(colors: colors),
        const SizedBox(height: AppSpacing.sm),
        // Task rows
        ...List.generate(4, (_) => _SkeletonRow(colors: colors)),
      ],
    );
  }
}

/// Skeleton placeholder for the schedule health strip area.
class _SkeletonHealthStrip extends StatelessWidget {
  final OnTaskColors colors;

  const _SkeletonHealthStrip({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          7,
          (_) => Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton row matching [TodayTaskRow] proportions:
/// 40pt time label placeholder + title area + trailing indicator.
class _SkeletonRow extends StatelessWidget {
  final OnTaskColors colors;

  const _SkeletonRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // 40pt time label placeholder
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Title area placeholder
          Expanded(
            child: Container(
              height: 14,
              color: colors.surfaceSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Trailing indicator placeholder
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
