import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/data/lists_repository.dart';
import 'package:ontask/features/lists/data/sharing_repository.dart';
import 'package:ontask/features/lists/domain/list_member.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/list_settings_screen.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  const testListId = 'b0000000-0000-4000-8000-000000000001';

  Widget buildScreen({
    ListsRepository? listsRepo,
    SharingRepository? sharingRepo,
    String? listStrategy,
  }) {
    final fakeListsRepo = listsRepo ?? _FakeListsRepository(strategy: listStrategy);
    final fakeSharingRepo = sharingRepo ?? _FakeSharingRepository();

    return ProviderScope(
      overrides: [
        listsRepositoryProvider.overrideWithValue(fakeListsRepo),
        sharingRepositoryProvider.overrideWithValue(fakeSharingRepo),
        listsProvider.overrideWith(
          () => _FakeListsNotifier(strategy: listStrategy),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const ListSettingsScreen(listId: testListId),
      ),
    );
  }

  group('ListSettingsScreen', () {
    testWidgets('renders all four strategy options', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.assignmentStrategyNone), findsOneWidget);
      expect(find.text(AppStrings.assignmentStrategyRoundRobin), findsOneWidget);
      expect(find.text(AppStrings.assignmentStrategyLeastBusy), findsOneWidget);
      expect(find.text(AppStrings.assignmentStrategyAiAssisted), findsOneWidget);
    });

    testWidgets('tapping round-robin calls updateAssignmentStrategy with correct value',
        (tester) async {
      final fakeRepo = _FakeListsRepository();
      await tester.pumpWidget(buildScreen(listsRepo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.assignmentStrategyRoundRobin));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdatedStrategy, equals('round-robin'));
      expect(fakeRepo.lastUpdatedListId, equals(testListId));
    });

    testWidgets('"Auto-assign now" button is disabled when strategy is null', (tester) async {
      await tester.pumpWidget(buildScreen(listStrategy: null));
      await tester.pumpAndSettle();

      // When strategy is null, the onPressed is null (button disabled)
      final button = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, AppStrings.assignmentAutoAssignButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('"Auto-assign now" button is enabled when strategy is set', (tester) async {
      await tester.pumpWidget(buildScreen(listStrategy: 'round-robin'));
      await tester.pumpAndSettle();

      final button = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, AppStrings.assignmentAutoAssignButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping auto-assign calls autoAssign on SharingRepository', (tester) async {
      final fakeSharingRepo = _FakeSharingRepository();
      await tester.pumpWidget(
        buildScreen(listStrategy: 'round-robin', sharingRepo: fakeSharingRepo),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(CupertinoButton, AppStrings.assignmentAutoAssignButton),
      );
      await tester.pumpAndSettle();

      expect(fakeSharingRepo.autoAssignCalled, isTrue);
      expect(fakeSharingRepo.lastAutoAssignListId, equals(testListId));
    });
  });
}

// ── Fake repositories ────────────────────────────────────────────────────────

class _FakeListsRepository extends ListsRepository {
  _FakeListsRepository({this.strategy})
      : super(ApiClient(baseUrl: 'http://fake'));

  final String? strategy;
  String? lastUpdatedListId;
  String? lastUpdatedStrategy;

  @override
  Future<TaskList> updateAssignmentStrategy(String listId, String? newStrategy) async {
    lastUpdatedListId = listId;
    lastUpdatedStrategy = newStrategy;
    return TaskList(
      id: listId,
      title: 'Test List',
      position: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      assignmentStrategy: newStrategy,
    );
  }

  @override
  Future<List<TaskList>> getLists() async => [
        TaskList(
          id: 'b0000000-0000-4000-8000-000000000001',
          title: 'Test List',
          position: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          assignmentStrategy: strategy,
        ),
      ];
}

class _FakeSharingRepository extends SharingRepository {
  _FakeSharingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  bool autoAssignCalled = false;
  String? lastAutoAssignListId;

  @override
  Future<Map<String, dynamic>> autoAssign(String listId) async {
    autoAssignCalled = true;
    lastAutoAssignListId = listId;
    return {'assigned': 2, 'strategy': 'round-robin', 'assignments': []};
  }

  @override
  Future<List<ListMember>> getListMembers(String listId) async => [];
}

// ── Fake notifier ────────────────────────────────────────────────────────────

class _FakeListsNotifier extends ListsNotifier {
  _FakeListsNotifier({this.strategy});

  final String? strategy;

  @override
  Future<List<TaskList>> build() async => [
        TaskList(
          id: 'b0000000-0000-4000-8000-000000000001',
          title: 'Test List',
          position: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          assignmentStrategy: strategy,
        ),
      ];
}
