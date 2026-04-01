import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/lists/data/sharing_repository.dart';
import 'package:ontask/features/lists/domain/list_member.dart';
import 'package:ontask/features/lists/presentation/widgets/share_list_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSheet({
    _FakeSharingRepository? fakeRepo,
    bool shouldThrow = false,
  }) {
    final repo = fakeRepo ?? _FakeSharingRepository(shouldThrow: shouldThrow);
    return ProviderScope(
      overrides: [
        sharingRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const Scaffold(
          body: ShareListSheet(
            listId: 'list-1',
            listTitle: 'Household Chores',
          ),
        ),
      ),
    );
  }

  group('ShareListSheet', () {
    testWidgets('shows email field and send button', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(CupertinoTextField, AppStrings.shareListEmailPlaceholder),
        findsOneWidget,
      );
      expect(find.text(AppStrings.shareListSendButton), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.shareListTitle), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty on submit',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.shareListSendButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.shareListErrorInvalidEmail), findsOneWidget);
    });

    testWidgets('shows validation error when email format is invalid',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Enter invalid email (no @)
      await tester.enterText(
        find.widgetWithText(CupertinoTextField, AppStrings.shareListEmailPlaceholder),
        'notanemail',
      );
      await tester.tap(find.text(AppStrings.shareListSendButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.shareListErrorInvalidEmail), findsOneWidget);
    });

    testWidgets('calls shareList on valid email submission', (tester) async {
      final fakeRepo = _FakeSharingRepository();
      await tester.pumpWidget(buildSheet(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(CupertinoTextField, AppStrings.shareListEmailPlaceholder),
        'sam@example.com',
      );
      await tester.tap(find.text(AppStrings.shareListSendButton));
      await tester.pumpAndSettle();

      expect(fakeRepo.shareListCalled, isTrue);
      expect(fakeRepo.lastEmail, equals('sam@example.com'));
    });

    testWidgets('shows success message after successful submission',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(CupertinoTextField, AppStrings.shareListEmailPlaceholder),
        'sam@example.com',
      );
      await tester.tap(find.text(AppStrings.shareListSendButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sam@example.com'),
        findsOneWidget,
      );
    });

    testWidgets('shows generic error when submission fails', (tester) async {
      await tester.pumpWidget(buildSheet(shouldThrow: true));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(CupertinoTextField, AppStrings.shareListEmailPlaceholder),
        'sam@example.com',
      );
      await tester.tap(find.text(AppStrings.shareListSendButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.shareListErrorGeneric), findsOneWidget);
    });
  });
}

/// Fake [SharingRepository] for widget tests.
class _FakeSharingRepository extends SharingRepository {
  _FakeSharingRepository({this.shouldThrow = false})
      : super(ApiClient(baseUrl: 'http://fake'));

  final bool shouldThrow;
  bool shareListCalled = false;
  String? lastEmail;

  @override
  Future<Map<String, dynamic>> shareList(String listId, String email) async {
    if (shouldThrow) throw Exception('Network error');
    shareListCalled = true;
    lastEmail = email;
    return {'invitationId': 'inv-1', 'listId': listId, 'inviteeEmail': email, 'status': 'pending'};
  }

  @override
  Future<InvitationDetails> getInvitationDetails(String token) async {
    return const InvitationDetails(
      listId: 'list-1',
      listTitle: 'Test',
      invitedByName: 'Jordan',
      inviteeEmail: 'sam@example.com',
    );
  }

  @override
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    return {'listId': 'list-1', 'listTitle': 'Test', 'invitedByName': 'Jordan', 'membershipId': 'mem-1'};
  }

  @override
  Future<void> declineInvitation(String token) async {}

  @override
  Future<List<ListMember>> getListMembers(String listId) async => [];
}
