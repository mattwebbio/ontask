import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/lists/data/sharing_repository.dart';

// Unit tests for SharingRepository.unassignTask (Story 5.3, AC3).
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
}
