// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current search query text with 300ms debounce.
///
/// Each keystroke resets the debounce timer. The actual state update
/// only fires after 300ms of inactivity, preventing excessive API calls.

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

/// Holds the current search query text with 300ms debounce.
///
/// Each keystroke resets the debounce timer. The actual state update
/// only fires after 300ms of inactivity, preventing excessive API calls.
final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  /// Holds the current search query text with 300ms debounce.
  ///
  /// Each keystroke resets the debounce timer. The actual state update
  /// only fires after 300ms of inactivity, preventing excessive API calls.
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'04a99bc3cc480d464dabed61d14b5402f7807b5a';

/// Holds the current search query text with 300ms debounce.
///
/// Each keystroke resets the debounce timer. The actual state update
/// only fires after 300ms of inactivity, preventing excessive API calls.

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Holds the current active search filter state.
///
/// Provides methods to add/remove individual filter dimensions.

@ProviderFor(ActiveSearchFilter)
final activeSearchFilterProvider = ActiveSearchFilterProvider._();

/// Holds the current active search filter state.
///
/// Provides methods to add/remove individual filter dimensions.
final class ActiveSearchFilterProvider
    extends $NotifierProvider<ActiveSearchFilter, SearchFilter> {
  /// Holds the current active search filter state.
  ///
  /// Provides methods to add/remove individual filter dimensions.
  ActiveSearchFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSearchFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSearchFilterHash();

  @$internal
  @override
  ActiveSearchFilter create() => ActiveSearchFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchFilter>(value),
    );
  }
}

String _$activeSearchFilterHash() =>
    r'e09c31b57c9de6936f5bdc9fa816440097a8a939';

/// Holds the current active search filter state.
///
/// Provides methods to add/remove individual filter dimensions.

abstract class _$ActiveSearchFilter extends $Notifier<SearchFilter> {
  SearchFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchFilter, SearchFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchFilter, SearchFilter>,
              SearchFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetches search results based on the current query and filter state.
///
/// Returns an empty list when no query is entered AND no filters are active.
/// Review fix #5: uses ref.watch (not ref.read) for searchRepositoryProvider.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Fetches search results based on the current query and filter state.
///
/// Returns an empty list when no query is entered AND no filters are active.
/// Review fix #5: uses ref.watch (not ref.read) for searchRepositoryProvider.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SearchResult>>,
          List<SearchResult>,
          FutureOr<List<SearchResult>>
        >
    with
        $FutureModifier<List<SearchResult>>,
        $FutureProvider<List<SearchResult>> {
  /// Fetches search results based on the current query and filter state.
  ///
  /// Returns an empty list when no query is entered AND no filters are active.
  /// Review fix #5: uses ref.watch (not ref.read) for searchRepositoryProvider.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<SearchResult>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SearchResult>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'376516e50b95956dee9b5e881a70b9fc4f53b946';
