import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/lists/domain/list_member.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/list_members_provider.dart';
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

  final testList = TaskList(
    id: 'list-1',
    title: 'Household Chores',
    position: 0,
    createdAt: DateTime(2026, 3, 31),
    updatedAt: DateTime(2026, 3, 31),
  );

  final twoMembers = [
    ListMember(
      userId: 'user-1',
      displayName: 'Jordan',
      avatarInitials: 'J',
      role: 'owner',
      joinedAt: DateTime(2026, 3, 31),
    ),
    ListMember(
      userId: 'user-2',
      displayName: 'Sam',
      avatarInitials: 'S',
      role: 'member',
      joinedAt: DateTime(2026, 3, 31),
    ),
  ];

  Widget buildWidget({
    required AsyncValue<List<ListMember>> membersOverride,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
        listsProvider.overrideWith(
          () => _FakeListsNotifier(AsyncData([testList])),
        ),
        listMembersProvider('list-1').overrideWith(
          () => _FakeListMembersNotifier(membersOverride),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const ListsScreen(),
      ),
    );
  }

  group('ListsScreen shared indicator', () {
    testWidgets('shows member avatars when list has 2+ members', (tester) async {
      await tester.pumpWidget(
        buildWidget(membersOverride: AsyncData(twoMembers)),
      );
      await tester.pumpAndSettle();

      // Member count label should be visible
      expect(
        find.textContaining('2 members'),
        findsOneWidget,
      );
    });

    testWidgets('shows first initial of each member in avatar text',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(membersOverride: AsyncData(twoMembers)),
      );
      await tester.pumpAndSettle();

      expect(find.text('J'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('shows no shared indicator for personal list (1 member)',
        (tester) async {
      final oneMember = [twoMembers.first];
      await tester.pumpWidget(
        buildWidget(membersOverride: AsyncData(oneMember)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('member'), findsNothing);
    });

    testWidgets('shows no shared indicator when members list is empty',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(membersOverride: const AsyncData([])),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('member'), findsNothing);
    });

    testWidgets('shows no shared indicator on loading state', (tester) async {
      await tester.pumpWidget(
        buildWidget(membersOverride: const AsyncLoading()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('member'), findsNothing);
    });

    testWidgets('shows no shared indicator on error state', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          membersOverride: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('member'), findsNothing);
    });
  });
}

/// Fake [ListsNotifier] for testing.
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
    return [];
  }
}

/// Fake [ListMembersNotifier] for testing.
class _FakeListMembersNotifier extends ListMembersNotifier {
  _FakeListMembersNotifier(this._value);
  final AsyncValue<List<ListMember>> _value;

  @override
  Future<List<ListMember>> build(String listId) async {
    if (_value is AsyncData<List<ListMember>>) {
      return (_value as AsyncData<List<ListMember>>).value;
    }
    if (_value is AsyncError<List<ListMember>>) {
      throw (_value as AsyncError<List<ListMember>>).error;
    }
    return [];
  }
}
