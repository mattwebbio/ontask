import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/list_detail_screen.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/presentation/tasks_provider.dart';
import 'package:ontask/features/lists/presentation/sections_provider.dart';
import 'package:ontask/features/lists/domain/section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final testList = TaskList(
    id: 'list-1',
    title: 'Work tasks',
    position: 0,
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  final testTasks = [
    Task(
      id: 'task-1',
      title: 'Buy groceries',
      listId: 'list-1',
      position: 0,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
    Task(
      id: 'task-2',
      title: 'Write report',
      listId: 'list-1',
      position: 1,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    ),
  ];

  Widget buildWidget({
    List<TaskList>? lists,
    List<Task>? tasks,
    List<Section>? sections,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
        listsProvider.overrideWith(
          () => _FakeListsNotifier(lists ?? [testList]),
        ),
        tasksProvider.overrideWith(
          () => _FakeTasksNotifier(tasks ?? testTasks),
        ),
        sectionsProvider.overrideWith(
          () => _FakeSectionsNotifier(sections ?? []),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const ListDetailScreen(listId: 'list-1'),
      ),
    );
  }

  group('ListDetailScreen', () {
    testWidgets('shows list title in navigation bar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Work tasks'), findsOneWidget);
    });

    testWidgets('shows tasks from provider', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Write report'), findsOneWidget);
    });

    testWidgets('shows "Show archived" toggle', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.showArchived), findsOneWidget);
    });

    testWidgets('toggles between Show/Hide archived', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.showArchived), findsOneWidget);
      await tester.tap(find.text(AppStrings.showArchived));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.hideArchived), findsOneWidget);
    });

    testWidgets('shows Add task and Add section buttons', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskInList), findsOneWidget);
      expect(find.text(AppStrings.addSectionInList), findsOneWidget);
    });
  });
}

class _FakeListsNotifier extends ListsNotifier {
  _FakeListsNotifier(this._lists);
  final List<TaskList> _lists;

  @override
  Future<List<TaskList>> build() async => _lists;
}

class _FakeTasksNotifier extends TasksNotifier {
  _FakeTasksNotifier(this._tasks);
  final List<Task> _tasks;

  @override
  Future<List<Task>> build({String? listId, String? sectionId}) async =>
      _tasks;
}

class _FakeSectionsNotifier extends SectionsNotifier {
  _FakeSectionsNotifier(this._sections);
  final List<Section> _sections;

  @override
  Future<List<Section>> build(String listId) async => _sections;
}
