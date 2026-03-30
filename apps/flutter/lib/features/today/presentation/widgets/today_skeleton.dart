import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Skeleton loading placeholder for the Today tab.
///
/// Shows 4 skeleton task rows with a shimmer sweep animation (1.2s loop,
/// left-to-right gradient). Wrapped in [RepaintBoundary] to isolate repaints.
///
/// Reduced-motion: when [MediaQuery.disableAnimations] is true, renders a
/// static fill with no shimmer animation.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    // Reduced motion: skip shimmer animation
    if (MediaQuery.of(context).disableAnimations) {
      return _buildSkeletonRows(colors);
    }

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.surfaceSecondary,
        highlightColor: colors.surfacePrimary,
        period: const Duration(milliseconds: 1200),
        child: _buildSkeletonRows(colors),
      ),
    );
  }

  Widget _buildSkeletonRows(OnTaskColors colors) {
    return Column(
      children: List.generate(4, (_) => _SkeletonRow(colors: colors)),
    );
  }
}

/// A single skeleton task row.
@visibleForTesting
class SkeletonRow extends StatelessWidget {
  final OnTaskColors colors;

  const SkeletonRow({required this.colors, super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonRow(colors: colors);
  }
}

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
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  color: colors.surfaceSecondary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 11,
                  width: 120,
                  color: colors.surfaceSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
