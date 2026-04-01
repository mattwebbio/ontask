import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/nonprofit.dart';

// Category filter options shown in the horizontal chip row.
const _categories = ['All', 'Health', 'Environment', 'Education', 'Human Rights', 'Animals'];

/// Pure display widget for searching and browsing nonprofits.
///
/// No Riverpod — caller passes data and callbacks.
/// Used inside [CharitySheetScreen] (Epic 6, Story 6.3, AC1).
class CharitySearchDelegate extends StatefulWidget {
  const CharitySearchDelegate({
    super.key,
    required this.nonprofits,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSelected,
    this.selectedCharityId,
  });

  /// Current search results to display.
  final List<Nonprofit> nonprofits;

  /// Whether a search/load is in progress.
  final bool isLoading;

  /// Called when the search text changes.
  final void Function(String query) onSearchChanged;

  /// Called when the active category chip changes. Null means "All".
  final void Function(String? category) onCategoryChanged;

  /// Called when the user taps a nonprofit row.
  final void Function(Nonprofit nonprofit) onSelected;

  /// ID of the currently selected nonprofit (for checkmark display).
  final String? selectedCharityId;

  @override
  State<CharitySearchDelegate> createState() => _CharitySearchDelegateState();
}

class _CharitySearchDelegateState extends State<CharitySearchDelegate> {
  String? _activeCategory; // null = "All"

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      color: colors.surfacePrimary,
      child: Column(
        children: [
          // ── Search input ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: CupertinoSearchTextField(
              placeholder: AppStrings.charitySearchPlaceholder,
              onChanged: widget.onSearchChanged,
            ),
          ),

          // ── Category filter row ─────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final label = _categories[index];
                final isAll = label == 'All';
                final isActive = isAll ? _activeCategory == null : _activeCategory == label;

                return GestureDetector(
                  onTap: () {
                    final newCategory = isAll ? null : label;
                    setState(() => _activeCategory = newCategory);
                    widget.onCategoryChanged(newCategory);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? colors.surfacePrimary : Colors.grey.shade200,
                      border: Border.all(
                        color: isActive ? colors.accentPrimary : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? colors.accentPrimary : colors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Results list / loading / empty state ────────────────────────
          Expanded(
            child: widget.isLoading && widget.nonprofits.isEmpty
                ? const Center(child: CupertinoActivityIndicator())
                : !widget.isLoading && widget.nonprofits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            AppStrings.charitySearchEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.nonprofits.length,
                        itemBuilder: (context, index) {
                          final nonprofit = widget.nonprofits[index];
                          final isSelected = nonprofit.id == widget.selectedCharityId;

                          return Semantics(
                            focusable: index == 0,
                            label: nonprofit.name,
                            child: GestureDetector(
                              onTap: () => widget.onSelected(nonprofit),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfacePrimary,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Logo or fallback icon
                                    nonprofit.logoUrl != null
                                        ? Image.network(
                                            nonprofit.logoUrl!,
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, e, stack) => Icon(
                                              CupertinoIcons.heart_fill,
                                              color: colors.accentPrimary,
                                              size: 24,
                                            ),
                                          )
                                        : Icon(
                                            CupertinoIcons.heart_fill,
                                            color: colors.accentPrimary,
                                            size: 24,
                                          ),
                                    const SizedBox(width: AppSpacing.sm),

                                    // Name and description
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nonprofit.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          if (nonprofit.description != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              nonprofit.description!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: colors.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Selected checkmark
                                    if (isSelected) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      Icon(
                                        CupertinoIcons.checkmark_circle_fill,
                                        color: colors.accentPrimary,
                                        size: 22,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
