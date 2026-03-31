import 'package:flutter/cupertino.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/proof_mode.dart';

/// Stateless widget that renders the proof mode icon and label.
///
/// - [ProofMode.standard]: empty widget (no indicator)
/// - [ProofMode.photo]: camera icon + "Photo proof"
/// - [ProofMode.watchMode]: eye icon + "Watch Mode"
/// - [ProofMode.healthKit]: heart icon + "HealthKit"
/// - [ProofMode.calendarEvent]: calendar icon + "Calendar event"
class ProofModeIndicator extends StatelessWidget {
  final ProofMode proofMode;
  final Color textColor;

  const ProofModeIndicator({
    required this.proofMode,
    required this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (proofMode == ProofMode.standard) {
      return const SizedBox.shrink();
    }

    final (icon, label) = _iconAndLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
          ),
        ),
      ],
    );
  }

  (IconData, String) get _iconAndLabel {
    switch (proofMode) {
      case ProofMode.photo:
        return (CupertinoIcons.camera, AppStrings.nowCardProofPhoto);
      case ProofMode.watchMode:
        return (CupertinoIcons.eye, AppStrings.nowCardProofWatchMode);
      case ProofMode.healthKit:
        return (CupertinoIcons.heart, AppStrings.nowCardProofHealthKit);
      case ProofMode.calendarEvent:
        return (CupertinoIcons.calendar, AppStrings.nowCardProofCalendarEvent);
      case ProofMode.standard:
        // Should not reach here since we return early above
        return (CupertinoIcons.circle, '');
    }
  }
}
