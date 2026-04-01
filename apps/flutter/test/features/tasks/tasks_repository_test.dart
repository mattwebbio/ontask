import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/tasks/data/tasks_repository.dart';

// Unit tests for TasksRepository.getTaskProof (Story 5.5, AC1).
//
// Uses the same mocktail MockDio / MockApiClient pattern established in
// apps/flutter/test/features/lists/sharing_repository_test.dart.

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(RequestOptions(path: ''));
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('TasksRepository.getTaskProof (Story 5.5, AC1)', () {
    test(
        'sends GET to /v1/tasks/{taskId}/proof and returns response data map',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/tasks/task-id/proof';

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-id',
              'proofMediaUrl': 'https://placehold.co/600x400.jpg',
              'proofRetained': true,
              'completedAt': '2026-04-01T08:00:00.000Z',
              'completedByUserId': 'd0000000-0000-4000-8000-000000000002',
              'completedByName': 'Jordan',
            },
          },
        ),
      );

      final repo = TasksRepository(mockClient);
      final result = await repo.getTaskProof('task-id');

      // Verify GET request was made to the correct path
      final captured = verify(
        () => mockDio.get<Map<String, dynamic>>(captureAny()),
      ).captured;
      expect(captured.single, equals(expectedPath));

      // Verify returned map contains expected fields
      expect(result['taskId'], equals('task-id'));
      expect(result['proofMediaUrl'], equals('https://placehold.co/600x400.jpg'));
      expect(result['proofRetained'], isTrue);
      expect(result['completedByName'], equals('Jordan'));
    });

    test('returns map with null proofMediaUrl when proof is not retained',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/tasks/task-abc/proof'),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-abc',
              'proofMediaUrl': null,
              'proofRetained': false,
              'completedAt': null,
              'completedByUserId': null,
              'completedByName': null,
            },
          },
        ),
      );

      final repo = TasksRepository(mockClient);
      final result = await repo.getTaskProof('task-abc');

      expect(result['proofMediaUrl'], isNull);
      expect(result['proofRetained'], isFalse);
      expect(result['completedByName'], isNull);
    });

    test('propagates DioException when the request fails', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/tasks/task-id/proof'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/tasks/task-id/proof'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final repo = TasksRepository(mockClient);

      await expectLater(
        () => repo.getTaskProof('task-id'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
