import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/lists/data/sharing_repository.dart';

// Unit tests for SharingRepository — Stories 5.3 and 5.6.
//
// Uses the same mocktail MockDio / MockApiClient pattern established in
// apps/flutter/test/features/auth/auth_repository_test.dart.

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(RequestOptions(path: ''));
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SharingRepository.unassignTask (AC3)', () {
    test(
        'sends DELETE to /v1/lists/{listId}/tasks/{taskId}/assignment and returns response map',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/lists/list-id/tasks/task-id/assignment';

      when(
        () => mockDio.delete<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-id',
              'listId': 'list-id',
              'previousAssigneeId': 'prev-user-id',
            },
          },
        ),
      );

      final repo = SharingRepository(mockClient);
      final result = await repo.unassignTask('list-id', 'task-id');

      // (1) Verify HTTP method is DELETE and (2) URL is correct
      final captured = verify(
        () => mockDio.delete<Map<String, dynamic>>(captureAny()),
      ).captured;
      expect(captured.single, equals(expectedPath));

      // (3) Verify returned map contains expected fields
      expect(result['taskId'], equals('task-id'));
      expect(result['listId'], equals('list-id'));
      expect(result['previousAssigneeId'], equals('prev-user-id'));
    });

    test('returns previousAssigneeId from response data', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.delete<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
              path: '/v1/lists/list-abc/tasks/task-xyz/assignment'),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-xyz',
              'listId': 'list-abc',
              'previousAssigneeId': 'd0000000-0000-4000-8000-000000000002',
            },
          },
        ),
      );

      final repo = SharingRepository(mockClient);
      final result = await repo.unassignTask('list-abc', 'task-xyz');

      expect(result['previousAssigneeId'],
          equals('d0000000-0000-4000-8000-000000000002'));
    });

    test('propagates DioException when the request fails', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.delete<Map<String, dynamic>>(any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
              path: '/v1/lists/list-id/tasks/task-id/assignment'),
          response: Response(
            requestOptions: RequestOptions(
                path: '/v1/lists/list-id/tasks/task-id/assignment'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final repo = SharingRepository(mockClient);

      await expectLater(
        () => repo.unassignTask('list-id', 'task-id'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Story 5.6: Member management (FR62, FR75) ────────────────────────────

  group('SharingRepository.removeMember (AC1)', () {
    test('sends DELETE to /v1/lists/{listId}/members/{userId} and returns response map',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/lists/list-id/members/user-id';

      when(
        () => mockDio.delete<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'listId': 'list-id',
              'removedUserId': 'user-id',
              'unassignedTaskCount': 1,
            },
          },
        ),
      );

      final repo = SharingRepository(mockClient);
      final result = await repo.removeMember('list-id', 'user-id');

      // Verify DELETE method and correct URL
      final captured = verify(
        () => mockDio.delete<Map<String, dynamic>>(captureAny()),
      ).captured;
      expect(captured.single, equals(expectedPath));

      // Verify returned map contains expected fields
      expect(result['listId'], equals('list-id'));
      expect(result['removedUserId'], equals('user-id'));
      expect(result['unassignedTaskCount'], equals(1));
    });
  });

  group('SharingRepository.leaveList (AC2)', () {
    test('sends POST to /v1/lists/{listId}/leave and returns response map',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/lists/list-id/leave';

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'listId': 'list-id',
              'unassignedTaskCount': 1,
            },
          },
        ),
      );

      final repo = SharingRepository(mockClient);
      final result = await repo.leaveList('list-id');

      // Verify POST method and correct URL
      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));

      // Verify returned map contains expected fields
      expect(result['listId'], equals('list-id'));
      expect(result['unassignedTaskCount'], equals(1));
    });
  });

  group('SharingRepository.updateMemberRole (AC3)', () {
    test(
        'sends PATCH to /v1/lists/{listId}/members/{userId}/role with role body',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/lists/list-id/members/user-id/role';

      when(
        () => mockDio.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'listId': 'list-id',
              'userId': 'user-id',
              'role': 'owner',
            },
          },
        ),
      );

      final repo = SharingRepository(mockClient);
      final result = await repo.updateMemberRole('list-id', 'user-id', 'owner');

      // Verify PATCH method and correct URL
      final captured = verify(
        () => mockDio.patch<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));

      // Verify returned map contains expected fields
      expect(result['listId'], equals('list-id'));
      expect(result['userId'], equals('user-id'));
      expect(result['role'], equals('owner'));
    });

    test('sends correct role body in PATCH request', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      Map<String, dynamic>? capturedData;

      when(
        () => mockDio.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        capturedData =
            invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(
              path: '/v1/lists/list-id/members/user-id/role'),
          statusCode: 200,
          data: {
            'data': {'listId': 'list-id', 'userId': 'user-id', 'role': 'owner'},
          },
        );
      });

      final repo = SharingRepository(mockClient);
      await repo.updateMemberRole('list-id', 'user-id', 'owner');

      expect(capturedData, isNotNull);
      expect(capturedData!['role'], equals('owner'));
    });

    test(
        'sends PATCH with role body {"role": "member"} when revoking owner (revoke path)',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      Map<String, dynamic>? capturedData;

      when(
        () => mockDio.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        capturedData =
            invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(
              path: '/v1/lists/list-id/members/user-id/role'),
          statusCode: 200,
          data: {
            'data': {'listId': 'list-id', 'userId': 'user-id', 'role': 'member'},
          },
        );
      });

      final repo = SharingRepository(mockClient);
      final result = await repo.updateMemberRole('list-id', 'user-id', 'member');

      expect(capturedData, isNotNull);
      expect(capturedData!['role'], equals('member'));
      expect(result['role'], equals('member'));
    });
  });
}
