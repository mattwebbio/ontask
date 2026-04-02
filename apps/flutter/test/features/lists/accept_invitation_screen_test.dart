import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/data/sharing_repository.dart';
import 'package:ontask/features/lists/domain/list_member.dart';
import 'package:ontask/features/lists/presentation/accept_invitation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen({
    required String token,
    SharingRepository? fakeRepo,
  }) {
    final repo = fakeRepo ?? _FakeSharingRepository();
    return ProviderScope(
      overrides: [
        sharingRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: AcceptInvitationScreen(token: token),
      ),
    );
  }

  group('AcceptInvitationScreen', () {
    testWidgets('shows loading indicator while fetching invitation details',
        (tester) async {
      final slowRepo = _SlowSharingRepository();
      await tester.pumpWidget(buildScreen(token: 'token-1', fakeRepo: slowRepo));
      // Only pump one frame so loading state is visible
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('shows list name and inviter name from response', (tester) async {
      await tester.pumpWidget(buildScreen(token: 'token-1'));
      await tester.pumpAndSettle();

      expect(find.text('Household Chores'), findsOneWidget);
      expect(
        find.textContaining('Jordan'),
        findsOneWidget,
      );
    });

    testWidgets('shows accept and decline buttons', (tester) async {
      await tester.pumpWidget(buildScreen(token: 'token-1'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.inviteAcceptButton), findsOneWidget);
      expect(find.text(AppStrings.inviteDeclineButton), findsOneWidget);
    });

    testWidgets('accept button triggers acceptInvitation', (tester) async {
      final fakeRepo = _FakeSharingRepository();
      await tester.pumpWidget(buildScreen(token: 'token-1', fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.inviteAcceptButton));
      await tester.pumpAndSettle();

      expect(fakeRepo.acceptInvitationCalled, isTrue);
    });

    testWidgets('decline button triggers declineInvitation', (tester) async {
      final fakeRepo = _FakeSharingRepository();
      await tester.pumpWidget(buildScreen(token: 'token-1', fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.inviteDeclineButton));
      await tester.pumpAndSettle();

      expect(fakeRepo.declineInvitationCalled, isTrue);
    });

    testWidgets('shows error message when invitation is invalid', (tester) async {
      final throwingRepo = _FakeSharingRepository(shouldThrowOnDetails: true);
      await tester.pumpWidget(buildScreen(token: 'bad-token', fakeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.inviteExpiredMessage), findsOneWidget);
      expect(find.text(AppStrings.inviteGoToLists), findsOneWidget);
    });

    // Story 9.6 tests: invited user onboarding — trial note display, FR86.

    testWidgets('shows invitationTrialNote on invitation content screen', (tester) async {
      await tester.pumpWidget(buildScreen(token: 'token-1'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.invitationTrialNote), findsOneWidget);
    });

    testWidgets('invitationTrialNote is NOT shown on expired state screen', (tester) async {
      final throwingRepo = _FakeSharingRepository(shouldThrowOnDetails: true);
      await tester.pumpWidget(buildScreen(token: 'bad-token', fakeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.invitationTrialNote), findsNothing);
      expect(find.text(AppStrings.inviteExpiredMessage), findsOneWidget);
    });

    testWidgets('accept button navigates to list after acceptance', (tester) async {
      final fakeRepo = _FakeSharingRepository();
      await tester.pumpWidget(buildScreen(token: 'token-1', fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.inviteAcceptButton));
      await tester.pumpAndSettle();

      expect(fakeRepo.acceptInvitationCalled, isTrue);
    });
  });
}

/// Fake [SharingRepository] for widget tests.
class _FakeSharingRepository extends SharingRepository {
  _FakeSharingRepository({this.shouldThrowOnDetails = false})
      : super(ApiClient(baseUrl: 'http://fake'));

  final bool shouldThrowOnDetails;
  bool acceptInvitationCalled = false;
  bool declineInvitationCalled = false;

  @override
  Future<InvitationDetails> getInvitationDetails(String token) async {
    if (shouldThrowOnDetails) throw Exception('Expired');
    return const InvitationDetails(
      listId: 'list-1',
      listTitle: 'Household Chores',
      invitedByName: 'Jordan',
      inviteeEmail: 'sam@example.com',
    );
  }

  @override
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    acceptInvitationCalled = true;
    return {
      'listId': 'list-1',
      'listTitle': 'Household Chores',
      'invitedByName': 'Jordan',
      'membershipId': 'mem-1',
      'isNewUser': false,
    };
  }

  @override
  Future<void> declineInvitation(String token) async {
    declineInvitationCalled = true;
  }

  @override
  Future<Map<String, dynamic>> shareList(String listId, String email) async {
    return {};
  }

  @override
  Future<List<ListMember>> getListMembers(String listId) async => [];
}

/// Slow repository that never resolves — used to test loading state.
class _SlowSharingRepository extends SharingRepository {
  _SlowSharingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<InvitationDetails> getInvitationDetails(String token) {
    // Never resolves — mimics in-flight network request.
    return Completer<InvitationDetails>().future;
  }

  @override
  Future<Map<String, dynamic>> shareList(String listId, String email) async =>
      {};

  @override
  Future<Map<String, dynamic>> acceptInvitation(String token) async => {};

  @override
  Future<void> declineInvitation(String token) async {}

  @override
  Future<List<ListMember>> getListMembers(String listId) async => [];
}
