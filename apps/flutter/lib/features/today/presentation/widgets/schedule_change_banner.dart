import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/schedule_change.dart';
import '../schedule_change_provider.dart';

/// Async wrapper that shows [ScheduleChangeBanner] only when the banner
/// is visible and schedule change data is available.
///
/// Shows [SizedBox.shrink] for loading, error, or dismissed states.
class ScheduleChangeBannerAsync extends ConsumerStatefulWidget {
  const ScheduleChangeBannerAsync({super.key});

  @override
  ConsumerState<ScheduleChangeBannerAsync> createState() =>
      _ScheduleChangeBannerAsyncState();
}

class _ScheduleChangeBannerAsyncState
    extends ConsumerState<ScheduleChangeBannerAsync> {
  bool _hapticFired = false;

  @override
  Widget build(BuildContext context) {
    final bannerVisible = ref.watch(scheduleChangeBannerVisibleProvider);
    final changesAsync = ref.watch(scheduleChangesProvider);

    final isVisible = bannerVisible.value == true;

    if (isVisible && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.lightImpact();
    }

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return changesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (changes) => ScheduleChangeBanner(changes: changes),
    );
  }
}

/// Inline banner showing schedule change notification at top of Today content.
///
/// Anatomy per UX-DR18:
/// - Icon + message + "See what changed" action + dismiss (×)
/// - Slides in from top; auto-dismissed after 8s (managed by TodayScreen)
/// - VoiceOver: liveRegion wrapping for VoiceOver announcement on appearance
class ScheduleChangeBanner extends ConsumerWidget {
  final ScheduleChanges changes;

  const ScheduleChangeBanner({required this.changes, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final bgColor = colors.scheduleAtRisk.withValues(alpha: 0.12);

    return Semantics(
      liveRegion: true,
      label: AppStrings.scheduleChangeBannerVoiceOver
          .replaceFirst('{count}', '${changes.changeCount}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.arrow_2_circlepath,
              size: 18,
              color: colors.scheduleAtRisk,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppStrings.scheduleChangeBannerMessage,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () => _showChangesSheet(context, changes.changes),
              child: Text(
                AppStrings.scheduleChangeSeeWhat,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.scheduleAtRisk,
                ),
              ),
            ),
            Semantics(
              label: AppStrings.scheduleChangeDismissVoiceOver,
              child: CupertinoButton(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                minSize: 0,
                onPressed: () => ref
                    .read(scheduleChangeBannerVisibleProvider.notifier)
                    .dismiss(),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangesSheet(
      BuildContext context, List<ScheduleChangeItem> changes) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text(AppStrings.scheduleChangesSheetTitle),
        actions: changes.map((item) {
          final summary = item.changeType == ScheduleChangeType.removed
              ? AppStrings.scheduleChangeRemovedFormat
                  .replaceFirst('{title}', item.taskTitle)
              : _buildMovedSummary(item);
          return CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(summary),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionDone),
        ),
      ),
    );
  }

  String _buildMovedSummary(ScheduleChangeItem item) {
    final time = item.newTime != null ? _formatTime(item.newTime!) : '—';
    return AppStrings.scheduleChangeMovedFormat
        .replaceFirst('{title}', item.taskTitle)
        .replaceFirst('{time}', time);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.toLocal().hour;
    final minute = dt.toLocal().minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour =
        hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    if (minute == 0) return '$displayHour$period';
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }
}
