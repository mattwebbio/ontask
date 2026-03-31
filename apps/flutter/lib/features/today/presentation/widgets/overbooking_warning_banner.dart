import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/overbooking_status.dart';
import '../overbooking_provider.dart';

/// Inline overbooking warning banner for the Today tab.
///
/// Anatomy per UX-DR16:
/// - Icon (triangle for at-risk, circle for critical) + severity colour + message
/// - Action row: Reschedule, Extend deadline, Acknowledge (+ optional partner action)
/// - Icon + text — never colour alone (NFR-A4)
/// - VoiceOver: liveRegion wrapping
class OverbookingWarningBanner extends StatelessWidget {
  final OverbookingStatus status;
  final VoidCallback? onReschedule;
  final VoidCallback? onExtendDeadline;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onRequestExtension;

  const OverbookingWarningBanner({
    required this.status,
    this.onReschedule,
    this.onExtendDeadline,
    this.onAcknowledge,
    this.onRequestExtension,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    final severityColor = status.severity == OverbookingSeverity.critical
        ? colors.scheduleCritical
        : colors.scheduleAtRisk;

    final icon = status.severity == OverbookingSeverity.critical
        ? CupertinoIcons.exclamationmark_circle
        : CupertinoIcons.exclamationmark_triangle;

    final bgColor = severityColor.withValues(alpha: 0.12);
    final percentStr = status.capacityPercent.toStringAsFixed(0);
    final hasStakeTask =
        status.overbookedTasks.any((t) => t.hasStake);

    return Semantics(
      liveRegion: true,
      label: AppStrings.overbookingWarningVoiceOver
          .replaceFirst('{percent}', percentStr),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + message row
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: severityColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.overbookingWarningMessage
                        .replaceFirst('{percent}', percentStr),
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Action row
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                _ActionButton(
                  label: AppStrings.overbookingReschedule,
                  color: severityColor,
                  onPressed: onReschedule,
                ),
                _ActionButton(
                  label: AppStrings.overbookingExtendDeadline,
                  color: severityColor,
                  onPressed: onExtendDeadline,
                ),
                _ActionButton(
                  label: AppStrings.overbookingAcknowledge,
                  color: severityColor,
                  onPressed: onAcknowledge,
                ),
                if (hasStakeTask)
                  _ActionButton(
                    label: AppStrings.overbookingRequestExtension,
                    color: severityColor,
                    onPressed: onRequestExtension,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }
}

/// Async wrapper that shows [OverbookingWarningBanner] when schedule is
/// overbooked and the banner has not been dismissed.
///
/// Shows [SizedBox.shrink] for loading, error, dismissed, or not overbooked states.
class OverbookingWarningBannerAsync extends ConsumerWidget {
  const OverbookingWarningBannerAsync({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(overbookingBannerDismissedProvider);
    final statusAsync = ref.watch(overbookingStatusProvider);

    if (dismissed) return const SizedBox.shrink();

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (!status.isOverbooked) return const SizedBox.shrink();

        return OverbookingWarningBanner(
          status: status,
          onAcknowledge: () =>
              ref.read(overbookingBannerDismissedProvider.notifier).dismiss(),
          onReschedule: () => _showNotImplemented(context),
          onExtendDeadline: () => _showNotImplemented(context),
          onRequestExtension: () => _showNotImplemented(context),
        );
      },
    );
  }

  void _showNotImplemented(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        content: const Text(AppStrings.actionNotImplemented),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.actionDone),
          ),
        ],
      ),
    );
  }
}
