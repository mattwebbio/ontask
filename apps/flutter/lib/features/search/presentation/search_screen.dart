import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'search_provider.dart';
import 'widgets/filter_chip_row.dart';
import 'widgets/search_result_row.dart';

/// Full-screen search overlay for iOS.
///
/// Presented as a [CupertinoPageRoute] (not a modal sheet — search needs
/// full keyboard + results space).
///
/// Layout:
/// - Top: CupertinoSearchTextField with autofocus
/// - Below search: filter chips row
/// - Below chips: active filter chips (removable)
/// - Results: search result rows
/// - Empty state: "No results found" or initial hint
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    // Review fix #4: typed as TextTheme, not dynamic
    final TextTheme textTheme = Theme.of(context).textTheme;
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final filter = ref.watch(activeSearchFilterProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surfacePrimary,
        middle: Text(
          AppStrings.searchFieldLabel,
          style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.searchCancel,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.accentPrimary,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search text field
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Semantics(
                label: AppStrings.searchFieldLabel,
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  autofocus: true,
                  placeholder: AppStrings.searchFieldPlaceholder,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).update(value);
                  },
                ),
              ),
            ),
            // Filter chips
            const FilterChipRow(),
            const SizedBox(height: AppSpacing.sm),
            // Results area
            Expanded(
              child: _buildResults(query, resultsAsync, filter, colors, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    String query,
    AsyncValue<List<dynamic>> resultsAsync,
    dynamic filter,
    OnTaskColors colors,
    TextTheme textTheme,
  ) {
    // Initial state: no query and no filters
    if (query.isEmpty && !(filter.isActive as bool)) {
      return Center(
        child: Text(
          AppStrings.searchInitialHint,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => Center(
        child: Text(
          AppStrings.listsError,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              AppStrings.searchNoResults,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SearchResultRow(
                  result: results[index],
                  highlightQuery: query.isNotEmpty ? query : null,
                  onTap: () {
                    // TODO(impl): navigate to task detail screen
                  },
                ),
                childCount: results.length,
              ),
            ),
          ],
        );
      },
    );
  }
}
