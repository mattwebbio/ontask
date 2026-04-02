import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';

// ── DisputeConfirmationView ───────────────────────────────────────────────────

/// Shared dispute confirmation widget shown after a dispute is successfully filed.
///
/// Displays all three trust-critical points simultaneously (UX-DR33):
///   1. Dispute received and under review.
///   2. Stake will not be charged during review.
///   3. Operator responds within 24 hours.
///
/// Used inline in all four proof sub-views' disputed state — NOT a separate route.
/// (Epic 7, Story 7.8, FR39-40, UX-DR33)
class DisputeConfirmationView extends StatelessWidget {
  const DisputeConfirmationView({
    super.key,
    required this.onDone,
  });

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shield checkmark icon — signals success/relief, not failure.
          Align(
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.checkmark_shield,
              color: colors.accentPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          // Heading — liveRegion for accessibility announcement.
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.disputeConfirmationTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Trust-critical point 1: dispute received.
          _TrustPoint(
            icon: CupertinoIcons.check_mark_circled,
            iconColor: colors.stakeZoneLow,
            label: AppStrings.disputeConfirmationPoint1,
            colors: colors,
          ),
          const SizedBox(height: 12),
          // Trust-critical point 2: stake on hold.
          _TrustPoint(
            icon: CupertinoIcons.lock_shield,
            iconColor: colors.accentPrimary,
            label: AppStrings.disputeConfirmationPoint2,
            colors: colors,
          ),
          const SizedBox(height: 12),
          // Trust-critical point 3: 24-hour response.
          _TrustPoint(
            icon: CupertinoIcons.clock,
            iconColor: colors.textSecondary,
            label: AppStrings.disputeConfirmationPoint3,
            colors: colors,
          ),
          const SizedBox(height: 24),
          // Done CTA — dismisses the modal.
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.accentPrimary,
            onPressed: onDone,
            child: Text(
              AppStrings.disputeConfirmationDoneCta,
              style: TextStyle(color: colors.surfacePrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trust point row ───────────────────────────────────────────────────────────

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
