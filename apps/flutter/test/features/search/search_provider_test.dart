import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/search/data/search_repository.dart';
import 'package:ontask/features/search/domain/search_filter.dart';
import 'package:ontask/features/search/domain/search_result.dart';
import 'package:ontask/features/search/domain/task_search_status.dart';
import 'package:ontask/features/search/presentation/search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchQuery', () {
    test('initial state is empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(searchQueryProvider), '');
    });

    test('setImmediate updates state immediately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).setImmediate('test');
      expect(container.read(searchQueryProvider), 'test');
    });

    test('debounce: update does not change state immediately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).update('hello');
      // State should still be empty immediately
      expect(container.read(searchQueryProvider), '');
    });

    test('setImmediate bypasses debounce', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // setImmediate should change state right away
      container.read(searchQueryProvider.notifier).setImmediate('hello');
      expect(container.read(searchQueryProvider), 'hello');

      // Verify subsequent setImmediate also works
      container.read(searchQueryProvider.notifier).setImmediate('world');
      expect(container.read(searchQueryProvider), 'world');
    });
  });

  group('ActiveSearchFilter', () {
    test('initial state is empty filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(activeSearchFilterProvider);
      expect(filter.isActive, isFalse);
      expect(filter.activeCount, 0);
    });

    test('setList updates list filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeSearchFilterProvider.notifier)
          .setList('list-1', 'Personal');
      final filter = container.read(activeSearchFilterProvider);
      expect(filter.listId, 'list-1');
      expect(filter.listName, 'Personal');
      expect(filter.isActive, isTrue);
    });

    test('removeList clears list filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeSearchFilterProvider.notifier)
          .setList('list-1', 'Personal');
      container.read(activeSearchFilterProvider.notifier).removeList();
      final filter = container.read(activeSearchFilterProvider);
      expect(filter.listId, isNull);
      expect(filter.listName, isNull);
    });

    test('activeCount reflects non-null fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeSearchFilterProvider.notifier)
          .setList('list-1', 'Work');
      container
          .read(activeSearchFilterProvider.notifier)
          .setStatus(TaskSearchStatus.completed);
      expect(container.read(activeSearchFilterProvider).activeCount, 2);
    });

    test('clearAll resets all filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeSearchFilterProvider.notifier)
          .setList('list-1', 'Work');
      container
          .read(activeSearchFilterProvider.notifier)
          .setStatus(TaskSearchStatus.completed);
      container.read(activeSearchFilterProvider.notifier).clearAll();
      expect(container.read(activeSearchFilterProvider).isActive, isFalse);
    });
  });

  group('searchResultsProvider', () {
    test('returns empty list when no query and no filters', () async {
      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider
              .overrideWithValue(_FakeSearchRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async resolution
      await container.read(searchResultsProvider.future);
      final results = container.read(searchResultsProvider).value;
      expect(results, isEmpty);
    });

    test('calls repository with query and filter', () async {
      final repo = _FakeSearchRepository();
      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Set a query immediately
      container.read(searchQueryProvider.notifier).setImmediate('groceries');

      // Wait for async resolution
      await container.read(searchResultsProvider.future);
      expect(repo.lastQuery, 'groceries');
    });
  });
}

class _FakeSearchRepository extends SearchRepository {
  String? lastQuery;
  SearchFilter? lastFilter;

  _FakeSearchRepository()
      : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<List<SearchResult>> search({
    String? query,
    SearchFilter? filter,
    String? cursor,
  }) async {
    lastQuery = query;
    lastFilter = filter;
    return [];
  }
}
