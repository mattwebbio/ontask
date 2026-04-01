import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/impact_milestone.dart';

/// A single impact milestone display cell (UX spec section 15, UX-DR19).
///
/// Displays the milestone [title] in New York serif (affirming voice copy),
/// the emotional [body] in New York italic, the [earnedAt] date, and a
/// Share button to invoke the native iOS share sheet via [onShare].
///
/// Copy is always affirming — no punitive language (UX-DR36).
/// Do NOT use streak language or progress-to-goal framing here.
class ImpactMilestoneCell extends StatelessWidget {
  const ImpactMilestoneCell({
    super.key,
    required this.milestone,
    required this.onShare,
  });

  final ImpactMilestone milestone;
  final VoidCallback onShare;

  /// Formats a [DateTime] as 'MMM d, yyyy' without the intl package.
  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final dateFormatted = _formatDate(milestone.earnedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Milestone title — New York 20pt Regular, affirming voice
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontFamily: 'NewYork',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                // Milestone body — New York 15pt Regular italic, emotional voice
                Text(
                  milestone.body,
                  style: const TextStyle(
                    fontFamily: 'NewYork',
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                // Earned date — SF Pro 13pt textSecondary
                Text(
                  dateFormatted,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Share button — native iOS share sheet
          CupertinoButton(
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            onPressed: onShare,
            child: const Icon(CupertinoIcons.share),
          ),
        ],
      ),
    );
  }
}
