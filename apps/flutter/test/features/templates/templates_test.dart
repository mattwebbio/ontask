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
import 'package:ontask/features/lists/presentation/create_list_screen.dart';
import 'package:ontask/features/lists/presentation/list_detail_screen.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:ontask/features/lists/presentation/lists_screen.dart';
import 'package:ontask/features/lists/presentation/sections_provider.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/presentation/tasks_provider.dart';
import 'package:ontask/features/templates/data/template_dto.dart';
import 'package:ontask/features/templates/domain/template.dart';
import 'package:ontask/features/templates/domain/template_source_type.dart';
import 'package:ontask/features/templates/presentation/template_picker_screen.dart';
import 'package:ontask/features/templates/presentation/templates_provider.dart';
import 'package:ontask/features/templates/presentation/templates_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Domain model tests ──────────────────────────────────────────────────

  group('Template domain model', () {
    test('fromJson/toJson round-trip via DTO', () {
      final json = {
        'id': 'c0000000-0000-4000-8000-000000000001',
        'userId': '00000000-0000-4000-a000-000000000001',
        'title': 'Sprint template',
        'sourceType': 'list',
        'templateData': '{"sections":[],"rootTasks":[]}',
        'createdAt': '2026-03-30T12:00:00.000Z',
        'updatedAt': '2026-03-30T12:00:00.000Z',
      };

      final dto = TemplateDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.id, 'c0000000-0000-4000-8000-000000000001');
      expect(domain.title, 'Sprint template');
      expect(domain.sourceType, 'list');
      expect(domain.templateData, '{"sections":[],"rootTasks":[]}');
      expect(domain.createdAt, DateTime.utc(2026, 3, 30, 12, 0, 0));

      // Convert back to JSON via DTO
      final backToJson = dto.toJson();
      expect(backToJson['id'], json['id']);
      expect(backToJson['title'], json['title']);
      expect(backToJson['sourceType'], json['sourceType']);
    });

    test('summary DTO (no templateData) maps correctly', () {
      final json = {
        'id': 'c0000000-0000-4000-8000-000000000001',
        'userId': '00000000-0000-4000-a000-000000000001',
        'title': 'My template',
        'sourceType': 'section',
        'createdAt': '2026-03-30T12:00:00.000Z',
      };

      final dto = TemplateDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.templateData, isNull);
      expect(domain.sourceType, 'section');
      expect(domain.updatedAt, isNull);
    });
  });

  group('TemplateSourceType enum', () {
    test('fromJson/toJson round-trip for list', () {
      final type = TemplateSourceType.fromJson('list');
      expect(type, TemplateSourceType.list);
      expect(type.toJson(), 'list');
    });

    test('fromJson/toJson round-trip for section', () {
      final type = TemplateSourceType.fromJson('section');
      expect(type, TemplateSourceType.section);
      expect(type.toJson(), 'section');
    });

    test('fromJson throws for unknown value', () {
      expect(
        () => TemplateSourceType.fromJson('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('TemplateDto', () {
    test('toDomain maps all fields correctly', () {
      final dto = TemplateDto(
        id: 'c0000000-0000-4000-8000-000000000001',
        userId: '00000000-0000-4000-a000-000000000001',
        title: 'Test template',
        sourceType: 'list',
        templateData: '{"sections":[]}',
        createdAt: '2026-03-30T12:00:00.000Z',
        updatedAt: '2026-03-30T12:00:00.000Z',
      );

      final domain = dto.toDomain();

      expect(domain.id, dto.id);
      expect(domain.userId, dto.userId);
      expect(domain.title, dto.title);
      expect(domain.sourceType, dto.sourceType);
      expect(domain.templateData, dto.templateData);
      expect(domain.createdAt, DateTime.utc(2026, 3, 30, 12, 0, 0));
      expect(domain.updatedAt, DateTime.utc(2026, 3, 30, 12, 0, 0));
    });
  });

  // ── Widget tests ────────────────────────────────────────────────────────

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
  ];

  final testTemplates = [
    Template(
      id: 'template-1',
      userId: 'user-1',
      title: 'Sprint planning',
      sourceType: 'list',
      createdAt: DateTime(2026, 3, 30),
    ),
    Template(
      id: 'template-2',
      userId: 'user-1',
      title: 'Weekly review',
      sourceType: 'section',
      createdAt: DateTime(2026, 3, 30),
    ),
  ];

  group('ListDetailScreen — Save as template', () {
    Widget buildListDetailWidget() {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(
            const AuthResult.authenticated(
                userId: 'user_1', provider: 'email'),
          ),
          listsProvider.overrideWith(
            () => _FakeListsNotifier([testList]),
          ),
          tasksProvider.overrideWith(
            () => _FakeTasksNotifier(testTasks),
          ),
          sectionsProvider.overrideWith(
            () => _FakeSectionsNotifier([]),
          ),
          templatesProvider.overrideWith(
            () => _FakeTemplatesNotifier(testTemplates),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const ListDetailScreen(listId: 'list-1'),
        ),
      );
    }

    testWidgets('shows overflow menu icon in nav bar', (tester) async {
      await tester.pumpWidget(buildListDetailWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.ellipsis_circle), findsOneWidget);
    });

    testWidgets(
        'tapping overflow menu shows "Save as template" action sheet',
        (tester) async {
      await tester.pumpWidget(buildListDetailWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.ellipsis_circle));
      await tester.pumpAndSettle();

      expect(
          find.text(AppStrings.templateSaveAsTemplate), findsOneWidget);
    });
  });

  group('CreateListScreen — Start from template', () {
    Widget buildCreateListWidget() {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(
            const AuthResult.authenticated(
                userId: 'user_1', provider: 'email'),
          ),
          listsProvider.overrideWith(
            () => _FakeListsNotifier([testList]),
          ),
          templatesProvider.overrideWith(
            () => _FakeTemplatesNotifier(testTemplates),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateListScreen(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    testWidgets('shows "Start from template" button', (tester) async {
      await tester.pumpWidget(buildCreateListWidget());
      await tester.pumpAndSettle();

      // Tap to open the create list sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Scroll down if needed to find the button
      await tester.dragUntilVisible(
        find.text(AppStrings.templateStartFromTemplate),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -100),
      );

      expect(
        find.text(AppStrings.templateStartFromTemplate),
        findsOneWidget,
      );
    });
  });

  group('TemplatePickerScreen', () {
    Widget buildPickerWidget({List<Template>? templates}) {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(
            const AuthResult.authenticated(
                userId: 'user_1', provider: 'email'),
          ),
          templatesProvider.overrideWith(
            () => _FakeTemplatesNotifier(templates ?? testTemplates),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const TemplatePickerScreen(),
        ),
      );
    }

    testWidgets('shows templates list', (tester) async {
      await tester.pumpWidget(buildPickerWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sprint planning'), findsOneWidget);
      expect(find.text('Weekly review'), findsOneWidget);
    });

    testWidgets('shows empty state when no templates', (tester) async {
      await tester.pumpWidget(buildPickerWidget(templates: []));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.templatePickerEmpty),
        findsOneWidget,
      );
    });

    testWidgets('tapping template shows apply sheet with offset picker',
        (tester) async {
      await tester.pumpWidget(buildPickerWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sprint planning'));
      await tester.pumpAndSettle();

      expect(
          find.text(AppStrings.templateApplyButton), findsOneWidget);
      expect(
          find.text(AppStrings.templateDueDateOffsetNone), findsOneWidget);
    });
  });

  group('TemplatesScreen', () {
    Widget buildTemplatesScreenWidget({List<Template>? templates}) {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(
            const AuthResult.authenticated(
                userId: 'user_1', provider: 'email'),
          ),
          templatesProvider.overrideWith(
            () => _FakeTemplatesNotifier(templates ?? testTemplates),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const TemplatesScreen(),
        ),
      );
    }

    testWidgets('shows templates with title and source type',
        (tester) async {
      await tester.pumpWidget(buildTemplatesScreenWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sprint planning'), findsOneWidget);
      expect(find.text('Weekly review'), findsOneWidget);
      expect(find.text(AppStrings.templateSourceList), findsOneWidget);
      expect(
          find.text(AppStrings.templateSourceSection), findsOneWidget);
    });

    testWidgets('shows empty state when no templates', (tester) async {
      await tester
          .pumpWidget(buildTemplatesScreenWidget(templates: []));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.templatePickerEmpty),
        findsOneWidget,
      );
    });

    testWidgets('swipe-to-delete shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(buildTemplatesScreenWidget());
      await tester.pumpAndSettle();

      // Swipe the first template row to the left
      await tester.drag(
        find.text('Sprint planning'),
        const Offset(-500, 0),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.templateDeleteConfirmTitle),
        findsOneWidget,
      );
    });
  });
}

// ── Fake notifiers for test overrides ─────────────────────────────────────

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

class _FakeTemplatesNotifier extends TemplatesNotifier {
  _FakeTemplatesNotifier(this._templates);
  final List<Template> _templates;

  @override
  Future<List<Template>> build() async => _templates;
}
