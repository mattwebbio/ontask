import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../search/presentation/search_provider.dart';
import '../../search/presentation/widgets/filter_chip_row.dart';
import '../../search/presentation/widgets/search_result_row.dart';

/// Command palette overlay — opened by Cmd+K on macOS.
///
/// Wired to search providers: typing in the text field triggers search results.
/// Filter chips are displayed below the search field.
/// Escape key dismisses the dialog.
///
/// Material violation fixes (from Story 2.9 dev notes):
/// - Dialog -> custom Container + BoxDecoration
/// - TextField -> CupertinoTextField
/// - InputDecoration / OutlineInputBorder removed
class CommandPaletteSheet extends ConsumerStatefulWidget {
  const CommandPaletteSheet({super.key});

  @override
  ConsumerState<CommandPaletteSheet> createState() =>
      _CommandPaletteSheetState();
}

class _CommandPaletteSheetState extends ConsumerState<CommandPaletteSheet> {
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true,
        // Material violation fix: Dialog -> custom Container with BoxDecoration
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 560, maxHeight: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.macosCommandPaletteTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Material violation fix: TextField -> CupertinoTextField
                    CupertinoTextField(
                      controller: _searchController,
                      autofocus: true,
                      placeholder: AppStrings.searchFieldPlaceholder,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                      ),
                      placeholderStyle: textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      onChanged: (value) {
                        ref
                            .read(searchQueryProvider.notifier)
                            .update(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Filter chips
                    const FilterChipRow(),
                    const SizedBox(height: AppSpacing.sm),
                    // Results
                    Expanded(
                      child: _buildResults(
                          query, resultsAsync, colors, textTheme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
    String query,
    AsyncValue<List<dynamic>> resultsAsync,
    OnTaskColors colors,
    TextTheme textTheme,
  ) {
    final filter = ref.watch(activeSearchFilterProvider);

    // Initial state: no query and no filters
    if (query.isEmpty && !filter.isActive) {
      return Center(
        child: Text(
          AppStrings.searchInitialHint,
          style: textTheme.bodySmall?.copyWith(
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
          style: textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              AppStrings.searchNoResults,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) => SearchResultRow(
            result: results[index],
            highlightQuery: query.isNotEmpty ? query : null,
            onTap: () {
              // TODO(impl): navigate to task detail screen
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
