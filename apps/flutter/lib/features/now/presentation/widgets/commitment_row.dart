import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Stateless widget for the stake/commitment display.
///
/// Shows a lock icon + formatted amount (e.g., "$25") + "at stake".
/// Returns [SizedBox.shrink()] when [stakeAmountCents] is null.
class CommitmentRow extends StatelessWidget {
  final int? stakeAmountCents;
  final Color textColor;

  const CommitmentRow({
    required this.stakeAmountCents,
    required this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (stakeAmountCents == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final formattedAmount = formatAmount(stakeAmountCents!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.lock, size: 16, color: textColor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          formattedAmount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.accentCompletion,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          AppStrings.nowCardStakeLabel,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// Formats cents to dollars, e.g. 2500 -> "$25".
  static String formatAmount(int cents) {
    final dollars = cents ~/ 100;
    final remainingCents = cents % 100;
    if (remainingCents == 0) {
      return '\$$dollars';
    }
    return '\$$dollars.${remainingCents.toString().padLeft(2, '0')}';
  }
}
