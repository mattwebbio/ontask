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
import 'package:ontask/features/lists/presentation/list_members_provider.dart';
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
    List<ListMember>? members,
  }) {
    final fakeListsRepo = listsRepo ?? _FakeListsRepository(strategy: listStrategy);
    final fakeSharingRepo = sharingRepo ?? _FakeSharingRepository(members: members);

    return ProviderScope(
      overrides: [
        listsRepositoryProvider.overrideWithValue(fakeListsRepo),
        sharingRepositoryProvider.overrideWithValue(fakeSharingRepo),
        listsProvider.overrideWith(
          () => _FakeListsNotifier(strategy: listStrategy),
        ),
        listMembersProvider(testListId).overrideWith(
          () => _FakeListMembersNotifier(members: members),
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

      // 'None' appears twice: once for assignment strategy and once for accountability
      expect(find.text(AppStrings.assignmentStrategyNone), findsAtLeastNWidgets(1));
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

      // Scroll down to ensure the auto-assign button is rendered in the viewport.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // The auto-assign CupertinoButton is the only CupertinoButton in the screen.
      // When strategy is null, the onPressed is null (button disabled).
      final autoAssignButtonFinder = find.ancestor(
        of: find.text(AppStrings.assignmentAutoAssignButton),
        matching: find.byType(CupertinoButton),
      );
      final button = tester.widget<CupertinoButton>(autoAssignButtonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('"Auto-assign now" button is enabled when strategy is set', (tester) async {
      await tester.pumpWidget(buildScreen(listStrategy: 'round-robin'));
      await tester.pumpAndSettle();

      // Scroll down to ensure the auto-assign button is rendered in the viewport.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final autoAssignButtonFinder = find.ancestor(
        of: find.text(AppStrings.assignmentAutoAssignButton),
        matching: find.byType(CupertinoButton),
      );
      final button = tester.widget<CupertinoButton>(autoAssignButtonFinder);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping auto-assign calls autoAssign on SharingRepository', (tester) async {
      final fakeSharingRepo = _FakeSharingRepository();
      await tester.pumpWidget(
        buildScreen(listStrategy: 'round-robin', sharingRepo: fakeSharingRepo),
      );
      await tester.pumpAndSettle();

      // Scroll down to ensure the auto-assign button is rendered in the viewport.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      await tester.tap(
        find.ancestor(
          of: find.text(AppStrings.assignmentAutoAssignButton),
          matching: find.byType(CupertinoButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeSharingRepo.autoAssignCalled, isTrue);
      expect(fakeSharingRepo.lastAutoAssignListId, equals(testListId));
    });
  });

  group('ListSettingsScreen — members section (Story 5.6, AC1/2/3)', () {
    final ownerMember = ListMember(
      userId: 'd0000000-0000-4000-8000-000000000001',
      displayName: 'Jordan',
      avatarInitials: 'J',
      role: 'owner',
      joinedAt: DateTime(2026),
    );

    final regularMember = ListMember(
      userId: 'd0000000-0000-4000-8000-000000000002',
      displayName: 'Sam',
      avatarInitials: 'S',
      role: 'member',
      joinedAt: DateTime(2026),
    );

    testWidgets('members section header renders', (tester) async {
      await tester.pumpWidget(buildScreen(members: [ownerMember, regularMember]));
      await tester.pumpAndSettle();

      // Scroll down to find the Members section
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.membersSettingsLabel), findsOneWidget);
    });

    testWidgets('member display name renders for stub member list', (tester) async {
      await tester.pumpWidget(buildScreen(members: [ownerMember, regularMember]));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    });

    testWidgets(
        'when current user is owner (Jordan), ellipsis button renders on member rows',
        (tester) async {
      await tester.pumpWidget(buildScreen(members: [ownerMember, regularMember]));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Owner management button (ellipsis_circle icon) should be visible
      expect(find.byIcon(CupertinoIcons.ellipsis_circle), findsWidgets);
    });

    testWidgets('when current user is NOT owner (Sam only), no management buttons shown',
        (tester) async {
      // Only Sam is a member (not the current user Jordan who is the stub owner)
      // Simulate: current user is Sam (non-owner). We achieve this by providing
      // a member list where the hardcoded current user ID (Jordan) has role 'member'.
      final jordanAsMember = ListMember(
        userId: 'd0000000-0000-4000-8000-000000000001',
        displayName: 'Jordan',
        avatarInitials: 'J',
        role: 'member', // not owner in this test
        joinedAt: DateTime(2026),
      );

      await tester.pumpWidget(buildScreen(members: [jordanAsMember, regularMember]));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // No ellipsis management buttons when current user is not owner
      expect(find.byIcon(CupertinoIcons.ellipsis_circle), findsNothing);
    });

    testWidgets('"Leave list" button renders for non-last-owner member',
        (tester) async {
      // Two owners exist — Jordan is not the last owner
      final secondOwner = ListMember(
        userId: 'd0000000-0000-4000-8000-000000000003',
        displayName: 'Alex',
        avatarInitials: 'A',
        role: 'owner',
        joinedAt: DateTime(2026),
      );

      await tester.pumpWidget(
          buildScreen(members: [ownerMember, regularMember, secondOwner]));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.leaveListButton), findsOneWidget);

      // Button should be enabled (not null onPressed) since Jordan is not last owner
      final leaveButton = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(AppStrings.leaveListButton),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(leaveButton.onPressed, isNotNull);
    });
  });

  group('ListSettingsScreen — accountability section (Story 5.4, AC1)', () {
    testWidgets('renders all four accountability options', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.accountabilitySettingsLabel), findsOneWidget);
      // Scroll to bring the accountability options into view
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.accountabilityPhoto), findsOneWidget);
      expect(find.text(AppStrings.accountabilityWatchMode), findsOneWidget);
      expect(find.text(AppStrings.accountabilityHealthKit), findsOneWidget);
    });

    testWidgets('tapping "Photo proof" calls updateListAccountability with correct value',
        (tester) async {
      final fakeRepo = _FakeListsRepository();
      await tester.pumpWidget(buildScreen(listsRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Scroll down to bring the accountability options into view
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.accountabilityPhoto));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdatedAccountabilityRequirement, equals('photo'));
      expect(fakeRepo.lastUpdatedAccountabilityListId, equals(testListId));
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
  String? lastUpdatedAccountabilityListId;
  String? lastUpdatedAccountabilityRequirement;

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
  Future<TaskList> updateListAccountability(String listId, String? proofRequirement) async {
    lastUpdatedAccountabilityListId = listId;
    lastUpdatedAccountabilityRequirement = proofRequirement;
    return TaskList(
      id: listId,
      title: 'Test List',
      position: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      proofRequirement: proofRequirement,
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
  _FakeSharingRepository({List<ListMember>? members})
      : _members = members ?? [],
        super(ApiClient(baseUrl: 'http://fake'));

  final List<ListMember> _members;
  bool autoAssignCalled = false;
  String? lastAutoAssignListId;

  @override
  Future<Map<String, dynamic>> autoAssign(String listId) async {
    autoAssignCalled = true;
    lastAutoAssignListId = listId;
    return {'assigned': 2, 'strategy': 'round-robin', 'assignments': []};
  }

  @override
  Future<List<ListMember>> getListMembers(String listId) async => _members;

  @override
  Future<Map<String, dynamic>> removeMember(String listId, String userId) async {
    return {'listId': listId, 'removedUserId': userId, 'unassignedTaskCount': 0};
  }

  @override
  Future<Map<String, dynamic>> leaveList(String listId) async {
    return {'listId': listId, 'unassignedTaskCount': 0};
  }

  @override
  Future<Map<String, dynamic>> updateMemberRole(
    String listId,
    String userId,
    String role,
  ) async {
    return {'listId': listId, 'userId': userId, 'role': role};
  }
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

class _FakeListMembersNotifier extends ListMembersNotifier {
  _FakeListMembersNotifier({List<ListMember>? members})
      : _members = members ?? [];

  final List<ListMember> _members;

  @override
  Future<List<ListMember>> build(String listId) async => _members;
}
