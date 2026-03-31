import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:ontask/features/lists/presentation/lists_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWidget({AsyncValue<List<TaskList>>? listsOverride}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
        if (listsOverride != null)
          listsProvider.overrideWith(() => _FakeListsNotifier(listsOverride)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const ListsScreen(),
      ),
    );
  }

  group('ListsScreen', () {
    testWidgets('shows empty state when no lists', (tester) async {
      await tester.pumpWidget(
        buildWidget(listsOverride: const AsyncData([])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.listsEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.listsEmptySubtitle), findsOneWidget);
    });

    testWidgets('shows create list CTA when no lists', (tester) async {
      await tester.pumpWidget(
        buildWidget(listsOverride: const AsyncData([])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createListButton), findsOneWidget);
    });

    testWidgets('shows user lists from provider', (tester) async {
      final lists = [
        TaskList(
          id: 'list-1',
          title: 'Work tasks',
          position: 0,
          createdAt: DateTime(2026, 3, 30),
          updatedAt: DateTime(2026, 3, 30),
        ),
        TaskList(
          id: 'list-2',
          title: 'Personal',
          position: 1,
          createdAt: DateTime(2026, 3, 30),
          updatedAt: DateTime(2026, 3, 30),
        ),
      ];
      await tester.pumpWidget(
        buildWidget(listsOverride: AsyncData(lists)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Work tasks'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('shows create list CTA when lists exist', (tester) async {
      final lists = [
        TaskList(
          id: 'list-1',
          title: 'Work tasks',
          position: 0,
          createdAt: DateTime(2026, 3, 30),
          updatedAt: DateTime(2026, 3, 30),
        ),
      ];
      await tester.pumpWidget(
        buildWidget(listsOverride: AsyncData(lists)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createListButton), findsOneWidget);
    });

    testWidgets('shows error message on error state', (tester) async {
      await tester.pumpWidget(
        buildWidget(listsOverride: AsyncError(Exception('fail'), StackTrace.current)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addTaskError), findsOneWidget);
    });
  });
}

/// Fake ListsNotifier for testing that returns the provided value directly.
class _FakeListsNotifier extends ListsNotifier {
  _FakeListsNotifier(this._value);
  final AsyncValue<List<TaskList>> _value;

  @override
  Future<List<TaskList>> build() async {
    if (_value is AsyncData<List<TaskList>>) {
      return (_value as AsyncData<List<TaskList>>).value;
    }
    if (_value is AsyncError<List<TaskList>>) {
      throw (_value as AsyncError<List<TaskList>>).error;
    }
    // AsyncLoading — return empty and set state to loading
    return [];
  }
}
