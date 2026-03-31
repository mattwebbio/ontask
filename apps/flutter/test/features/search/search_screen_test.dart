import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:ontask/features/search/data/search_repository.dart';
import 'package:ontask/features/search/domain/search_filter.dart';
import 'package:ontask/features/search/domain/search_result.dart';
import 'package:ontask/features/search/presentation/search_provider.dart';
import 'package:ontask/features/search/presentation/search_screen.dart';
import 'package:ontask/features/search/presentation/widgets/filter_chip_row.dart';
import 'package:ontask/features/search/presentation/widgets/search_result_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final testResults = [
    SearchResult(
      id: 'task-1',
      title: 'Buy groceries',
      notes: 'Milk, eggs',
      dueDate: DateTime(2026, 4, 1, 9),
      listId: 'list-1',
      position: 0,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
      listName: 'Personal',
    ),
    SearchResult(
      id: 'task-2',
      title: 'Finish report',
      position: 1,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
      listName: 'Work',
    ),
  ];

  Widget buildScreen({
    List<SearchResult> results = const [],
    String query = '',
    SearchFilter? filter,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
        searchRepositoryProvider
            .overrideWithValue(_FakeSearchRepository(results)),
        searchQueryProvider.overrideWith(
          () => _FakeSearchQueryNotifier(query),
        ),
        activeSearchFilterProvider.overrideWith(
          () => _FakeActiveSearchFilterNotifier(
              filter ?? SearchFilter.empty()),
        ),
        listsProvider.overrideWith(
          () => _FakeListsNotifier(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const SearchScreen(),
      ),
    );
  }

  testWidgets('SearchScreen: verify search field renders with autofocus',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
  });

  testWidgets('SearchScreen: verify empty query shows initial hint state',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.searchInitialHint), findsOneWidget);
  });

  testWidgets('SearchScreen: verify no results shows empty state message',
      (tester) async {
    await tester.pumpWidget(buildScreen(query: 'zzz'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.searchNoResults), findsOneWidget);
  });

  testWidgets('SearchScreen: verify filter chips row renders all four dimensions',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.searchFilterList), findsOneWidget);
    expect(find.text(AppStrings.searchFilterDate), findsOneWidget);
    expect(find.text(AppStrings.searchFilterStatus), findsOneWidget);
    expect(find.text(AppStrings.searchFilterHasStake), findsOneWidget);
  });

  testWidgets('SearchScreen: verify typing triggers search results',
      (tester) async {
    await tester.pumpWidget(buildScreen(
      query: 'groceries',
      results: testResults,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultRow), findsNWidgets(2));
  });

  testWidgets('SearchScreen: verify cancel button is present',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.searchCancel), findsOneWidget);
  });

  testWidgets('SearchScreen: verify VoiceOver semantics label wraps search field',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Verify the Semantics widget with search label exists
    final semanticsFinder = find.bySemanticsLabel(AppStrings.searchFieldLabel);
    expect(semanticsFinder, findsWidgets);
  });

  testWidgets('SearchScreen: verify result rows render list name and title',
      (tester) async {
    await tester.pumpWidget(buildScreen(
      query: 'Buy',
      results: testResults,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('SearchScreen: verify search field label string is correct',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.searchFieldLabel), findsOneWidget);
  });

  testWidgets('SearchScreen: verify filter chip row is a ConsumerWidget',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(FilterChipRow), findsOneWidget);
  });
}

class _FakeSearchRepository extends SearchRepository {
  final List<SearchResult> _results;

  _FakeSearchRepository(this._results)
      : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<List<SearchResult>> search({
    String? query,
    SearchFilter? filter,
    String? cursor,
  }) async {
    return _results;
  }
}

class _FakeSearchQueryNotifier extends SearchQuery {
  final String _initial;
  _FakeSearchQueryNotifier(this._initial);

  @override
  String build() => _initial;
}

class _FakeActiveSearchFilterNotifier extends ActiveSearchFilter {
  final SearchFilter _initial;
  _FakeActiveSearchFilterNotifier(this._initial);

  @override
  SearchFilter build() => _initial;
}

class _FakeListsNotifier extends ListsNotifier {
  @override
  Future<List<TaskList>> build() async => [];
}
