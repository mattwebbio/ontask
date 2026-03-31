import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/search_repository.dart';
import '../domain/search_filter.dart';
import '../domain/search_result.dart';
import '../domain/task_search_status.dart';

part 'search_provider.g.dart';

/// Holds the current search query text with 300ms debounce.
///
/// Each keystroke resets the debounce timer. The actual state update
/// only fires after 300ms of inactivity, preventing excessive API calls.
@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _debounceTimer;

  @override
  String build() {
    // Review fix #3: dispose timer when notifier is disposed
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }

  /// Updates the query with 300ms debounce.
  void update(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = value;
    });
  }

  /// Sets the query immediately without debounce (for programmatic use).
  void setImmediate(String value) {
    _debounceTimer?.cancel();
    state = value;
  }
}

/// Holds the current active search filter state.
///
/// Provides methods to add/remove individual filter dimensions.
@riverpod
class ActiveSearchFilter extends _$ActiveSearchFilter {
  @override
  SearchFilter build() => SearchFilter.empty();

  /// Sets the list filter.
  void setList(String listId, String listName) {
    state = state.copyWith(listId: listId, listName: listName);
  }

  /// Removes the list filter.
  void removeList() {
    state = state.copyWith(listId: null, listName: null);
  }

  /// Sets the date range filter.
  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(dueDateFrom: from, dueDateTo: to);
  }

  /// Removes the date range filter.
  void removeDateRange() {
    state = state.copyWith(dueDateFrom: null, dueDateTo: null);
  }

  /// Sets the status filter.
  void setStatus(TaskSearchStatus status) {
    state = state.copyWith(status: status);
  }

  /// Removes the status filter.
  void removeStatus() {
    state = state.copyWith(status: null);
  }

  /// Toggles the hasStake filter.
  void toggleHasStake() {
    state = state.copyWith(hasStake: state.hasStake == true ? null : true);
  }

  /// Removes the hasStake filter.
  void removeHasStake() {
    state = state.copyWith(hasStake: null);
  }

  /// Clears all filters.
  void clearAll() {
    state = SearchFilter.empty();
  }
}

/// Fetches search results based on the current query and filter state.
///
/// Returns an empty list when no query is entered AND no filters are active.
/// Review fix #5: uses ref.watch (not ref.read) for searchRepositoryProvider.
@riverpod
Future<List<SearchResult>> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(activeSearchFilterProvider);
  // Review fix #5: watch the repository so it reacts to API client changes
  final repo = ref.watch(searchRepositoryProvider);

  // No search when idle (no query and no active filters)
  if (query.isEmpty && !filter.isActive) {
    return [];
  }

  return repo.search(query: query, filter: filter);
}
