import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/search_result.dart';

/// Renders a single search result row with title, list name, due date,
/// and status indicator.
///
/// Highlights matched text in the title when [highlightQuery] is provided.
class SearchResultRow extends StatelessWidget {
  final SearchResult result;
  final String? highlightQuery;
  final VoidCallback? onTap;

  const SearchResultRow({
    required this.result,
    this.highlightQuery,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final statusLabel = result.completedAt != null
        ? AppStrings.searchFilterStatusCompleted
        : (result.dueDate != null && result.dueDate!.isBefore(DateTime.now()))
            ? AppStrings.searchFilterStatusOverdue
            : AppStrings.searchFilterStatusUpcoming;

    final voiceOverLabel =
        '${result.title}. ${result.listName ?? ''}. $statusLabel.';

    // Review fix #7: use onTapHint instead of button: true for navigational taps
    return Semantics(
      onTapHint: result.title,
      label: voiceOverLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(textTheme, colors),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (result.listName != null) ...[
                    Text(
                      result.listName!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (result.dueDate != null)
                    Text(
                      _formatDate(result.dueDate!),
                      style: textTheme.bodySmall?.copyWith(
                        color: result.completedAt == null &&
                                result.dueDate!.isBefore(DateTime.now())
                            ? colors.scheduleCritical
                            : colors.textSecondary,
                      ),
                    ),
                  const Spacer(),
                  _buildStatusIndicator(colors, textTheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme, OnTaskColors colors) {
    if (highlightQuery == null || highlightQuery!.isEmpty) {
      return Text(
        result.title,
        style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Build TextSpan with highlighted matches
    final spans = <TextSpan>[];
    final query = highlightQuery!.toLowerCase();
    final title = result.title;
    int start = 0;

    while (start < title.length) {
      final matchIndex = title.toLowerCase().indexOf(query, start);
      if (matchIndex == -1) {
        spans.add(TextSpan(
          text: title.substring(start),
          style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
        ));
        break;
      }
      if (matchIndex > start) {
        spans.add(TextSpan(
          text: title.substring(start, matchIndex),
          style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
        ));
      }
      spans.add(TextSpan(
        text: title.substring(matchIndex, matchIndex + query.length),
        style: textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusIndicator(OnTaskColors colors, TextTheme textTheme) {
    if (result.completedAt != null) {
      return Icon(
        CupertinoIcons.checkmark_circle_fill,
        size: 16,
        color: colors.accentCompletion,
      );
    }
    if (result.dueDate != null && result.dueDate!.isBefore(DateTime.now())) {
      return Text(
        AppStrings.searchFilterStatusOverdue,
        style: textTheme.labelSmall?.copyWith(
          color: colors.scheduleCritical,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return AppStrings.dateToday;
    if (dateOnly == tomorrow) return AppStrings.dateTomorrow;

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
}
