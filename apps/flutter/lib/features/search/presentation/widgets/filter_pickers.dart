import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../lists/presentation/lists_provider.dart';
import '../../domain/task_search_status.dart';
import '../search_provider.dart';

/// Shows a list picker using CupertinoActionSheet.
///
/// Lists are fetched from [listsProvider].
void showListFilterPicker(BuildContext context, WidgetRef ref) {
  final listsAsync = ref.read(listsProvider);
  final lists = listsAsync.value ?? [];

  final actions = lists.map((list) {
    return CupertinoActionSheetAction(
      onPressed: () {
        ref
            .read(activeSearchFilterProvider.notifier)
            .setList(list.id, list.title);
        Navigator.of(context).pop();
      },
      child: Text(list.title),
    );
  }).toList();

  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(AppStrings.searchFilterList),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text(AppStrings.actionCancel),
      ),
    ),
  );
}

/// Shows a date range picker with two CupertinoDatePickers (from/to).
///
/// Review fix #1: uses AppStrings for 'From'/'To' labels.
/// Review fix #2: uses theme text styles instead of hardcoded fontSize.
void showDateRangeFilterPicker(BuildContext context, WidgetRef ref) {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now().add(const Duration(days: 7));

  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      final colors = Theme.of(ctx).extension<OnTaskColors>()!;
      // Review fix #4: typed as TextTheme, not dynamic
      final TextTheme textTheme = Theme.of(ctx).textTheme;

      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: 420,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          AppStrings.actionCancel,
                          // Review fix #2: theme text style, no hardcoded fontSize
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.accentPrimary,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ref
                              .read(activeSearchFilterProvider.notifier)
                              .setDateRange(fromDate, toDate);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          AppStrings.actionDone,
                          // Review fix #2: theme text style, no hardcoded fontSize
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.accentPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Review fix #1: AppStrings for 'From' label
                  Text(
                    AppStrings.searchFilterDateFrom,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: fromDate,
                      onDateTimeChanged: (date) {
                        setModalState(() => fromDate = date);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Review fix #1: AppStrings for 'To' label
                  Text(
                    AppStrings.searchFilterDateTo,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: toDate,
                      onDateTimeChanged: (date) {
                        setModalState(() => toDate = date);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Shows a status filter picker using CupertinoActionSheet.
void showStatusFilterPicker(BuildContext context, WidgetRef ref) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(AppStrings.searchFilterStatus),
      actions: TaskSearchStatus.values.map((status) {
        return CupertinoActionSheetAction(
          onPressed: () {
            ref
                .read(activeSearchFilterProvider.notifier)
                .setStatus(status);
            Navigator.of(ctx).pop();
          },
          child: Text(status.displayLabel()),
        );
      }).toList(),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text(AppStrings.actionCancel),
      ),
    ),
  );
}
