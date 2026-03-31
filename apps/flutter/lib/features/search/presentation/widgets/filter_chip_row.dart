import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/search_filter.dart';
import '../search_provider.dart';
import 'filter_pickers.dart';

/// Horizontal row of filter dimension buttons + active filter chips.
///
/// Filter buttons: List, Date, Status, Has Stake.
/// Active filters show as removable chips below the buttons.
/// No Material Chip/FilterChip widgets — built from CupertinoButton + Container.
class FilterChipRow extends ConsumerWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activeSearchFilterProvider);
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter dimension buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _FilterButton(
                label: AppStrings.searchFilterList,
                isActive: filter.listId != null,
                onPressed: () => showListFilterPicker(context, ref),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(
                label: AppStrings.searchFilterDate,
                isActive: filter.dueDateFrom != null,
                onPressed: () => showDateRangeFilterPicker(context, ref),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(
                label: AppStrings.searchFilterStatus,
                isActive: filter.status != null,
                onPressed: () => showStatusFilterPicker(context, ref),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(
                label: AppStrings.searchFilterHasStake,
                isActive: filter.hasStake == true,
                onPressed: () => ref
                    .read(activeSearchFilterProvider.notifier)
                    .toggleHasStake(),
              ),
            ],
          ),
        ),
        // Active filter chips (removable)
        if (filter.isActive) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (filter.listId != null)
                  _ActiveChip(
                    label: filter.listName ?? AppStrings.searchFilterList,
                    onRemove: () => ref
                        .read(activeSearchFilterProvider.notifier)
                        .removeList(),
                    colors: colors,
                    textTheme: textTheme,
                  ),
                if (filter.dueDateFrom != null || filter.dueDateTo != null)
                  _ActiveChip(
                    label: _formatDateRange(
                        filter.dueDateFrom, filter.dueDateTo),
                    onRemove: () => ref
                        .read(activeSearchFilterProvider.notifier)
                        .removeDateRange(),
                    colors: colors,
                    textTheme: textTheme,
                  ),
                if (filter.status != null)
                  _ActiveChip(
                    label: filter.status!.displayLabel(),
                    onRemove: () => ref
                        .read(activeSearchFilterProvider.notifier)
                        .removeStatus(),
                    colors: colors,
                    textTheme: textTheme,
                  ),
                if (filter.hasStake == true)
                  _ActiveChip(
                    label: AppStrings.searchFilterHasStake,
                    onRemove: () => ref
                        .read(activeSearchFilterProvider.notifier)
                        .removeHasStake(),
                    colors: colors,
                    textTheme: textTheme,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateRange(DateTime? from, DateTime? to) {
    final fromStr = from != null
        ? '${from.month}/${from.day}'
        : '';
    final toStr = to != null
        ? '${to.month}/${to.day}'
        : '';
    if (fromStr.isNotEmpty && toStr.isNotEmpty) {
      return '$fromStr \u2013 $toStr';
    }
    return fromStr.isNotEmpty ? fromStr : toStr;
  }
}

/// A single filter dimension button (inactive state).
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? colors.accentPrimary : colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isActive
                ? colors.surfacePrimary
                : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// A removable active filter chip.
///
/// Review fix #6: 44pt minimum touch target on the X (remove) icon.
class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final OnTaskColors colors;
  final TextTheme textTheme;

  const _ActiveChip({
    required this.label,
    required this.onRemove,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label. ${AppStrings.searchFilterRemove}',
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.accentPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: colors.surfacePrimary,
              ),
            ),
            // Review fix #6: ensure 44x44pt minimum touch target for X icon
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: colors.surfacePrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
