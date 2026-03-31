import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_search_status.dart';

part 'search_filter.freezed.dart';

/// Active search filter state — each field represents a filter dimension.
///
/// All fields are nullable; null means "not filtered on this dimension".
/// Multiple non-null fields combine with AND logic.
@freezed
abstract class SearchFilter with _$SearchFilter {
  const SearchFilter._();

  const factory SearchFilter({
    String? query,
    String? listId,
    String? listName,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    TaskSearchStatus? status,
    bool? hasStake,
  }) = _SearchFilter;

  /// Factory for an empty (no-filter-active) state.
  factory SearchFilter.empty() => const SearchFilter();

  /// True if any filter dimension (excluding query) is active.
  bool get isActive =>
      listId != null ||
      dueDateFrom != null ||
      dueDateTo != null ||
      status != null ||
      hasStake != null;

  /// Count of active filter dimensions (excluding query).
  int get activeCount {
    int count = 0;
    if (listId != null) count++;
    if (dueDateFrom != null || dueDateTo != null) count++;
    if (status != null) count++;
    if (hasStake != null) count++;
    return count;
  }
}
