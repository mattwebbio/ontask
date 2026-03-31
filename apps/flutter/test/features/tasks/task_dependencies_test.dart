import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/tasks/data/task_dependency_dto.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/domain/task_dependency.dart';
import 'package:ontask/features/tasks/presentation/dependencies_provider.dart';
import 'package:ontask/features/tasks/presentation/tasks_provider.dart';
import 'package:ontask/features/tasks/data/tasks_repository.dart';
import 'package:ontask/features/tasks/presentation/widgets/dependency_picker.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_edit_inline.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final testTask = Task(
    id: 'task-1',
    title: 'Test task',
    position: 0,
    listId: 'list-1',
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  final prerequisiteTask = Task(
    id: 'task-2',
    title: 'Prerequisite task',
    position: 1,
    listId: 'list-1',
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  final sampleDependency = TaskDependency(
    id: 'dep-1',
    dependentTaskId: 'task-1',
    dependsOnTaskId: 'task-2',
    createdAt: DateTime(2026, 3, 30),
  );

  group('TaskDependency domain model', () {
    test('round-trip via DTO fromJson/toDomain', () {
      final json = {
        'id': 'dep-1',
        'dependentTaskId': 'task-1',
        'dependsOnTaskId': 'task-2',
        'createdAt': '2026-03-30T00:00:00.000Z',
      };

      final dto = TaskDependencyDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.id, 'dep-1');
      expect(domain.dependentTaskId, 'task-1');
      expect(domain.dependsOnTaskId, 'task-2');
      expect(domain.createdAt, isA<DateTime>());
    });

    test('DTO toJson produces correct keys', () {
      const dto = TaskDependencyDto(
        id: 'dep-1',
        dependentTaskId: 'task-1',
        dependsOnTaskId: 'task-2',
        createdAt: '2026-03-30T00:00:00.000Z',
      );
      final json = dto.toJson();
      expect(json['id'], 'dep-1');
      expect(json['dependentTaskId'], 'task-1');
      expect(json['dependsOnTaskId'], 'task-2');
      expect(json['createdAt'], '2026-03-30T00:00:00.000Z');
    });
  });

  group('DependencyPicker', () {
    testWidgets('lists available tasks', (tester) async {
      final tasks = [prerequisiteTask];
      Task? selectedTask;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: DependencyPicker(
              availableTasks: tasks,
              onSelected: (t) => selectedTask = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prerequisite task'), findsOneWidget);
      expect(find.text(AppStrings.taskDependencyPickerTitle), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: DependencyPicker(
              availableTasks: const [],
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.text(AppStrings.taskDependencyPickerEmpty), findsOneWidget);
    });

    testWidgets('tapping a task triggers onSelected', (tester) async {
      Task? selectedTask;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: DependencyPicker(
              availableTasks: [prerequisiteTask],
              onSelected: (t) => selectedTask = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prerequisite task'));
      expect(selectedTask?.id, 'task-2');
    });
  });

  group('TaskRow dependency indicator', () {
    testWidgets('shows dependency indicator when dependsOn is not empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: TaskRow(
              task: testTask,
              dependsOn: [sampleDependency],
              allTasks: [testTask, prerequisiteTask],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show "Depends on: Prerequisite task"
      expect(
        find.textContaining(AppStrings.taskDependsOn),
        findsOneWidget,
      );
    });

    testWidgets('shows blocks indicator when blocks is not empty',
        (tester) async {
      final blocksDep = TaskDependency(
        id: 'dep-2',
        dependentTaskId: 'task-2',
        dependsOnTaskId: 'task-1',
        createdAt: DateTime(2026, 3, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: TaskRow(
              task: testTask,
              blocks: [blocksDep],
              allTasks: [testTask, prerequisiteTask],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(AppStrings.taskBlocks),
        findsOneWidget,
      );
    });

    testWidgets('no dependency indicator when no dependencies', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: TaskRow(task: testTask),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(AppStrings.taskDependsOn), findsNothing);
      expect(find.textContaining(AppStrings.taskBlocks), findsNothing);
    });
  });

  group('TaskEditInline Dependencies section', () {
    testWidgets('shows Dependencies section label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthResult.authenticated(
                  userId: 'user_1', provider: 'email'),
            ),
            dependenciesProvider.overrideWith(
              () => _FakeDependenciesNotifier(),
            ),
            tasksProvider.overrideWith(
              () => _FakeTasksNotifier([testTask, prerequisiteTask]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: TaskEditInline(task: testTask),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.taskDependenciesLabel), findsOneWidget);
    });

    testWidgets('shows "Add dependency" button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthResult.authenticated(
                  userId: 'user_1', provider: 'email'),
            ),
            dependenciesProvider.overrideWith(
              () => _FakeDependenciesNotifier(),
            ),
            tasksProvider.overrideWith(
              () => _FakeTasksNotifier([testTask, prerequisiteTask]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: TaskEditInline(task: testTask),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to find the button
      await tester.dragUntilVisible(
        find.text(AppStrings.taskAddDependency),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      expect(find.text(AppStrings.taskAddDependency), findsOneWidget);
    });
  });
}

class _FakeDependenciesNotifier extends Dependencies {
  @override
  Future<DependencyState> build({required String taskId}) async =>
      (dependsOn: <TaskDependency>[], blocks: <TaskDependency>[]);
}

class _FakeTasksNotifier extends TasksNotifier {
  _FakeTasksNotifier(this._tasks);
  final List<Task> _tasks;

  @override
  Future<List<Task>> build({String? listId, String? sectionId}) async =>
      _tasks;
}
