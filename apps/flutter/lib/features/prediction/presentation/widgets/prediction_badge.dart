import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/completion_prediction.dart';

/// Stateless prediction badge that displays predicted completion status.
///
/// Anatomy per UX-DR17: small pill badge with calendar icon + predicted date text.
/// Status is always communicated via icon + colour — never colour alone (NFR-A4).
///
/// Callers are responsible for async loading; this widget receives a fully
/// resolved [CompletionPrediction] domain model.
class PredictionBadge extends StatelessWidget {
  const PredictionBadge({
    required this.prediction,
    super.key,
  });

  final CompletionPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final badgeColor = _colorForStatus(prediction.status, colors);
    final icon = _iconForStatus(prediction.status);
    final label = _labelForStatus(prediction.status, prediction.predictedDate);
    final voiceOverLabel = _voiceOverLabel(prediction.status, prediction.predictedDate);

    return Semantics(
      label: voiceOverLabel,
      button: true,
      child: GestureDetector(
        onTap: () => _showReasoningSheet(context),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: badgeColor.withValues(alpha: 0.12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: badgeColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForStatus(PredictionStatus status, OnTaskColors colors) {
    switch (status) {
      case PredictionStatus.onTrack:
        return colors.scheduleHealthy;
      case PredictionStatus.atRisk:
        return colors.scheduleAtRisk;
      case PredictionStatus.behind:
        return colors.scheduleCritical;
      case PredictionStatus.unknown:
        return colors.textSecondary;
    }
  }

  IconData _iconForStatus(PredictionStatus status) {
    switch (status) {
      case PredictionStatus.onTrack:
        return CupertinoIcons.calendar_badge_plus;
      case PredictionStatus.atRisk:
        return CupertinoIcons.exclamationmark_triangle;
      case PredictionStatus.behind:
        return CupertinoIcons.exclamationmark_circle;
      case PredictionStatus.unknown:
        return CupertinoIcons.calendar;
    }
  }

  String _labelForStatus(PredictionStatus status, DateTime? date) {
    if (status == PredictionStatus.unknown || date == null) {
      return AppStrings.predictionBadgeUnknown;
    }
    final dateStr = _formatDate(date);
    switch (status) {
      case PredictionStatus.onTrack:
        return AppStrings.predictionBadgeOnTrack.replaceAll('{date}', dateStr);
      case PredictionStatus.atRisk:
        return AppStrings.predictionBadgeAtRisk.replaceAll('{date}', dateStr);
      case PredictionStatus.behind:
        return AppStrings.predictionBadgeBehind.replaceAll('{date}', dateStr);
      case PredictionStatus.unknown:
        return AppStrings.predictionBadgeUnknown;
    }
  }

  String _voiceOverLabel(PredictionStatus status, DateTime? date) {
    if (status == PredictionStatus.unknown || date == null) {
      return AppStrings.predictionBadgeVoiceOverUnknown;
    }
    final statusStr = _statusStringForVoiceOver(status);
    final dateStr = _formatDate(date);
    return AppStrings.predictionBadgeVoiceOver
        .replaceAll('{status}', statusStr)
        .replaceAll('{date}', dateStr);
  }

  String _statusStringForVoiceOver(PredictionStatus status) {
    switch (status) {
      case PredictionStatus.onTrack:
        return 'on track';
      case PredictionStatus.atRisk:
        return 'at risk';
      case PredictionStatus.behind:
        return 'behind';
      case PredictionStatus.unknown:
        return 'unknown';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      AppStrings.monthJan,
      AppStrings.monthFeb,
      AppStrings.monthMar,
      AppStrings.monthApr,
      AppStrings.monthMay,
      AppStrings.monthJun,
      AppStrings.monthJul,
      AppStrings.monthAug,
      AppStrings.monthSep,
      AppStrings.monthOct,
      AppStrings.monthNov,
      AppStrings.monthDec,
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showReasoningSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text(AppStrings.predictionBadgeSheetTitle),
        message: Text(
          '${prediction.reasoning}\n\n'
          '${AppStrings.predictionBadgeTasksRemaining.replaceAll('{count}', '${prediction.tasksRemaining}')}\n'
          '${AppStrings.predictionBadgeEstimatedTime.replaceAll('{minutes}', '${prediction.estimatedMinutesRemaining}')}\n'
          '${AppStrings.predictionBadgeAvailableWindows.replaceAll('{count}', '${prediction.availableWindowsCount}')}',
        ),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionDone),
        ),
      ),
    );
  }
}
