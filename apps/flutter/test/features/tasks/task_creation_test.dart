import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/shell/presentation/add_tab_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: Builder(
            builder: (context) => CupertinoButton(
              child: const Text('Open'),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddTabSheet(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  group('AddTabSheet — task creation form', () {
    testWidgets('shows task creation title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskTitle), findsOneWidget);
    });

    testWidgets('shows title placeholder field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CupertinoTextField &&
              w.placeholder == AppStrings.addTaskTitlePlaceholder,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows notes placeholder field', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CupertinoTextField &&
              w.placeholder == AppStrings.addTaskNotesPlaceholder,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows due date label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskDueDateLabel), findsOneWidget);
    });

    testWidgets('shows create button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskCreateButton), findsOneWidget);
    });

    testWidgets('shows title required validation on empty submit',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap create without entering title
      await tester.tap(find.text(AppStrings.addTaskCreateButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskTitleRequired), findsOneWidget);
    });

    testWidgets('uses AppStrings, not inline strings', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify old inline strings are NOT present
      expect(find.text('Add a task'), findsNothing);
      expect(
        find.text('Task capture coming in a future story.'),
        findsNothing,
      );
    });
  });
}
