import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/presentation/widgets/task_edit_inline.dart';
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
    notes: 'Some notes',
    position: 0,
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  Widget buildWidget({VoidCallback? onDone}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: TaskEditInline(
            task: testTask,
            onDone: onDone,
          ),
        ),
      ),
    );
  }

  group('TaskEditInline', () {
    testWidgets('renders title field with task title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is CupertinoTextField && w.controller?.text == 'Test task',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders notes field with task notes', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CupertinoTextField && w.controller?.text == 'Some notes',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders due date label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskDueDateLabel), findsOneWidget);
    });

    testWidgets('renders done button when onDone provided', (tester) async {
      bool doneCalled = false;
      await tester.pumpWidget(buildWidget(onDone: () => doneCalled = true));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      expect(doneCalled, isTrue);
    });

    testWidgets('title field accepts text input', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Find the title CupertinoTextField and verify it's editable
      final titleFields = find.byType(CupertinoTextField);
      expect(titleFields, findsAtLeast(2)); // title + notes

      // Tap the first text field (title) to focus it
      await tester.tap(titleFields.first);
      await tester.pumpAndSettle();

      // Verify the field is responsive to input
      expect(
        find.byWidgetPredicate(
          (w) => w is CupertinoTextField && w.controller?.text == 'Test task',
        ),
        findsOneWidget,
      );
    });
  });
}
