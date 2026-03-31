import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/lists/domain/section.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/list_detail_screen.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:ontask/features/lists/presentation/sections_provider.dart';
import 'package:ontask/features/lists/presentation/widgets/bulk_actions_bar.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/presentation/tasks_provider.dart';
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

  Widget buildListDetailWidget({
    List<TaskList>? lists,
    List<Task>? tasks,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(
              userId: 'user_1', provider: 'email'),
        ),
        listsProvider.overrideWith(
          () => _FakeListsNotifier(lists ?? [testList]),
        ),
        tasksProvider.overrideWith(
          () => _FakeTasksNotifier(tasks ?? testTasks),
        ),
        sectionsProvider.overrideWith(
          () => _FakeSectionsNotifier([]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const ListDetailScreen(listId: 'list-1'),
      ),
    );
  }

  group('ListDetailScreen multi-select', () {
    testWidgets('long-press on task enters multi-select mode',
        (tester) async {
      await tester.pumpWidget(buildListDetailWidget());
      await tester.pumpAndSettle();

      // Long press on first task
      await tester.longPress(find.text('Buy groceries'));
      await tester.pumpAndSettle();

      // Should show selection count and Cancel button
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text(AppStrings.actionCancel), findsOneWidget);
    });

    testWidgets('shows checkboxes in multi-select mode', (tester) async {
      await tester.pumpWidget(buildListDetailWidget());
      await tester.pumpAndSettle();

      // Long press to enter multi-select
      await tester.longPress(find.text('Buy groceries'));
      await tester.pumpAndSettle();

      // Should show circle/checkmark icons (checkboxes)
      expect(
        find.byIcon(CupertinoIcons.checkmark_circle_fill),
        findsOneWidget, // selected task
      );
      expect(
        find.byIcon(CupertinoIcons.circle),
        findsOneWidget, // unselected task
      );
    });
  });

  group('BulkActionsBar', () {
    testWidgets('shows all four action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onReschedule: (_) {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.bulkRescheduleAction), findsOneWidget);
      expect(find.text(AppStrings.bulkCompleteAction), findsOneWidget);
      expect(find.text(AppStrings.bulkDeleteAction), findsOneWidget);
      expect(find.text(AppStrings.bulkAssignAction), findsOneWidget);
    });

    testWidgets('delete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onReschedule: (_) {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.bulkDeleteAction));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(
        find.text(AppStrings.bulkDeleteConfirmTitle.replaceAll('{count}', '2')),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.bulkDeleteConfirmMessage),
        findsOneWidget,
      );
    });

    testWidgets('complete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 3,
              onReschedule: (_) {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.bulkCompleteAction));
      await tester.pumpAndSettle();

      expect(
        find.text(
            AppStrings.bulkCompleteConfirmTitle.replaceAll('{count}', '3')),
        findsOneWidget,
      );
    });

    testWidgets('reschedule opens date picker', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onReschedule: (_) {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.bulkRescheduleAction));
      await tester.pumpAndSettle();

      // Date picker should be shown (with "Done" button)
      expect(find.text(AppStrings.actionDone), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });

    testWidgets('assign button is disabled', (tester) async {
      bool assignCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: BulkActionsBar(
              selectedCount: 2,
              onReschedule: (_) {},
              onComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assign button should be visible but tapping should not do anything
      expect(find.text(AppStrings.bulkAssignAction), findsOneWidget);

      // The button should have a Tooltip with the disabled message
      expect(find.byType(Tooltip), findsOneWidget);
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
