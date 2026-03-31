import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/day_health.dart';
import '../../domain/day_health_status.dart';

/// Horizontal row of 7 day chips (Mon-Sun) showing weekly schedule health.
///
/// Each chip is coloured green/amber/red based on [DayHealthStatus].
/// Tapping an amber or red chip shows a modal sheet listing at-risk tasks.
/// Health status is always communicated via icon + label, never colour alone (NFR-A4).
class ScheduleHealthStrip extends StatelessWidget {
  final List<DayHealth> days;

  const ScheduleHealthStrip({required this.days, super.key});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (i) {
          final day = days[i];
          final label = i < _dayLabels.length ? _dayLabels[i] : '';
          return _DayChip(day: day, label: label);
        }),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DayHealth day;
  final String label;

  const _DayChip({required this.day, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final chipColor = _colorForStatus(day.status, colors);
    final icon = _iconForStatus(day.status);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Semantics(
        label: '$label, ${_statusLabel(day.status)}',
        button: day.status != DayHealthStatus.healthy,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: chipColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForStatus(DayHealthStatus status, OnTaskColors colors) {
    switch (status) {
      case DayHealthStatus.healthy:
        return colors.scheduleHealthy;
      case DayHealthStatus.atRisk:
        return colors.scheduleAtRisk;
      case DayHealthStatus.critical:
        return colors.scheduleCritical;
    }
  }

  IconData _iconForStatus(DayHealthStatus status) {
    switch (status) {
      case DayHealthStatus.healthy:
        return CupertinoIcons.checkmark_circle;
      case DayHealthStatus.atRisk:
        return CupertinoIcons.exclamationmark_triangle;
      case DayHealthStatus.critical:
        return CupertinoIcons.exclamationmark_circle;
    }
  }

  String _statusLabel(DayHealthStatus status) {
    switch (status) {
      case DayHealthStatus.healthy:
        return AppStrings.scheduleHealthOnTrack;
      case DayHealthStatus.atRisk:
        return AppStrings.scheduleHealthAtRisk;
      case DayHealthStatus.critical:
        return AppStrings.scheduleHealthCritical;
    }
  }

  void _handleTap(BuildContext context) {
    // Only show detail for amber/red days
    if (day.status == DayHealthStatus.healthy) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(AppStrings.scheduleHealthAtRiskTasks),
        message: day.atRiskTaskIds.isEmpty
            ? Text(_statusLabel(day.status))
            : null,
        actions: day.atRiskTaskIds
            .map(
              (id) => CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(id),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionDone),
        ),
      ),
    );
  }
}
