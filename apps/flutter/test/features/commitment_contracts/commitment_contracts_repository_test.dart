import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/commitment_contracts/data/commitment_contracts_repository.dart';

// Unit tests for CommitmentContractsRepository — Story 6.1 (FR23, FR64).
//
// Uses the same mocktail MockDio / MockApiClient pattern established in
// apps/flutter/test/features/lists/sharing_repository_test.dart (Story 5.3).

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(RequestOptions(path: ''));
    FlutterSecureStorage.setMockInitialValues({});
  });

  // ── getPaymentStatus ──────────────────────────────────────────────────────

  group('CommitmentContractsRepository.getPaymentStatus (AC2)', () {
    test(
        'fires GET /v1/payment-method and maps hasPaymentMethod, last4, brand, hasActiveStakes',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/payment-method'),
          statusCode: 200,
          data: {
            'data': {
              'hasPaymentMethod': true,
              'paymentMethod': {'last4': '4242', 'brand': 'visa'},
              'hasActiveStakes': false,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final status = await repo.getPaymentStatus();

      final captured =
          verify(() => mockDio.get<Map<String, dynamic>>(captureAny()))
              .captured;
      expect(captured.single, equals('/v1/payment-method'));

      expect(status.hasPaymentMethod, isTrue);
      expect(status.last4, equals('4242'));
      expect(status.brand, equals('visa'));
      expect(status.hasActiveStakes, isFalse);
    });

    test('maps hasPaymentMethod=false and null paymentMethod fields when no method stored',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/payment-method'),
          statusCode: 200,
          data: {
            'data': {
              'hasPaymentMethod': false,
              'paymentMethod': null,
              'hasActiveStakes': false,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final status = await repo.getPaymentStatus();

      expect(status.hasPaymentMethod, isFalse);
      expect(status.last4, isNull);
      expect(status.brand, isNull);
      expect(status.hasActiveStakes, isFalse);
    });
  });

  // ── createSetupSession ────────────────────────────────────────────────────

  group('CommitmentContractsRepository.createSetupSession (AC1)', () {
    test(
        'fires POST /v1/payment-method/setup-session and returns setupUrl and sessionToken',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/payment-method/setup-session';

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 201,
          data: {
            'data': {
              'setupUrl': 'https://ontaskhq.com/setup?sessionToken=stub-token',
              'sessionToken': 'stub-token',
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.createSetupSession();

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));

      expect(
          result['setupUrl'],
          equals('https://ontaskhq.com/setup?sessionToken=stub-token'));
      expect(result['sessionToken'], equals('stub-token'));
    });
  });

  // ── confirmSetup ──────────────────────────────────────────────────────────

  group('CommitmentContractsRepository.confirmSetup (AC1)', () {
    test(
        'fires POST /v1/payment-method/confirm with body {"sessionToken": "stub-token"}',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/payment-method/confirm';
      Map<String, dynamic>? capturedBody;

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'hasPaymentMethod': true,
              'paymentMethod': {'last4': '4242', 'brand': 'visa'},
              'hasActiveStakes': false,
            },
          },
        );
      });

      final repo = CommitmentContractsRepository(mockClient);
      final status = await repo.confirmSetup('stub-token');

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));
      expect(capturedBody, isNotNull);
      expect(capturedBody!['sessionToken'], equals('stub-token'));

      expect(status.hasPaymentMethod, isTrue);
      expect(status.last4, equals('4242'));
      expect(status.brand, equals('visa'));
    });
  });

  // ── removePaymentMethod ───────────────────────────────────────────────────

  group('CommitmentContractsRepository.removePaymentMethod (AC2)', () {
    test('fires DELETE /v1/payment-method', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/payment-method';

      when(
        () => mockDio.delete<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {'removed': true},
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      await repo.removePaymentMethod();

      final captured = verify(
        () => mockDio.delete<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));
    });

    test('propagates DioException when the request fails with 422 (active stakes)',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.delete<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/payment-method'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/payment-method'),
            statusCode: 422,
            data: {
              'error': {
                'code': 'ACTIVE_STAKES_PREVENT_REMOVAL',
                'message': 'Active stakes prevent removal',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);

      await expectLater(
        () => repo.removePaymentMethod(),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── getTaskStake ──────────────────────────────────────────────────────────

  group('CommitmentContractsRepository.getTaskStake (Story 6.2)', () {
    test(
        'fires GET /v1/tasks/task-id/stake and maps taskId and stakeAmountCents',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/tasks/task-id/stake';

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-id',
              'stakeAmountCents': 2500,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getTaskStake('task-id');

      final captured =
          verify(() => mockDio.get<Map<String, dynamic>>(captureAny()))
              .captured;
      expect(captured.single, equals(expectedPath));
      expect(result.taskId, equals('task-id'));
      expect(result.stakeAmountCents, equals(2500));
    });

    test('maps stakeAmountCents as null when no stake set', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/tasks/task-id/stake'),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-id',
              'stakeAmountCents': null,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getTaskStake('task-id');

      expect(result.stakeAmountCents, isNull);
    });
  });

  // ── setTaskStake ──────────────────────────────────────────────────────────

  group('CommitmentContractsRepository.setTaskStake (Story 6.2)', () {
    test(
        'fires PUT /v1/tasks/task-id/stake with body {taskId, stakeAmountCents: 2500}',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/tasks/task-id/stake';
      Map<String, dynamic>? capturedBody;

      when(
        () => mockDio.put<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-id',
              'stakeAmountCents': 2500,
            },
          },
        );
      });

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.setTaskStake('task-id', 2500);

      final captured = verify(
        () => mockDio.put<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));
      expect(capturedBody, isNotNull);
      expect(capturedBody!['taskId'], equals('task-id'));
      expect(capturedBody!['stakeAmountCents'], equals(2500));
      expect(result.stakeAmountCents, equals(2500));
    });
  });

  // ── removeTaskStake ───────────────────────────────────────────────────────

  group('CommitmentContractsRepository.removeTaskStake (Story 6.2)', () {
    test('fires DELETE /v1/tasks/task-id/stake', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/tasks/task-id/stake';

      when(
        () => mockDio.delete<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {'removed': true},
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      await repo.removeTaskStake('task-id');

      final captured = verify(
        () => mockDio.delete<Map<String, dynamic>>(captureAny()),
      ).captured;
      expect(captured.single, equals(expectedPath));
    });
  });

  // ── searchCharities ───────────────────────────────────────────────────────

  group('CommitmentContractsRepository.searchCharities (Story 6.3)', () {
    test('fires GET /v1/charities with no params and maps nonprofit list', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/charities';

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'nonprofits': [
                {
                  'id': 'american-red-cross',
                  'name': 'American Red Cross',
                  'description': 'Emergency response and disaster relief.',
                  'logoUrl': null,
                  'categories': ['Health'],
                },
              ],
              'total': 1,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final results = await repo.searchCharities();

      final captured = verify(
        () => mockDio.get<Map<String, dynamic>>(
          captureAny(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));

      expect(results.length, equals(1));
      expect(results.first.id, equals('american-red-cross'));
      expect(results.first.name, equals('American Red Cross'));
      expect(results.first.categories, equals(['Health']));
    });

    test("fires GET /v1/charities?search=red+cross when query='red cross'", () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      Map<String, dynamic>? capturedQueryParams;

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((invocation) async {
        capturedQueryParams = invocation.namedArguments[const Symbol('queryParameters')]
            as Map<String, dynamic>?;
        return Response(
          requestOptions: RequestOptions(path: '/v1/charities'),
          statusCode: 200,
          data: {
            'data': {'nonprofits': [], 'total': 0},
          },
        );
      });

      final repo = CommitmentContractsRepository(mockClient);
      await repo.searchCharities(query: 'red cross');

      expect(capturedQueryParams, isNotNull);
      expect(capturedQueryParams!['search'], equals('red cross'));
    });

    test("fires GET /v1/charities?category=Health when category='Health'", () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      Map<String, dynamic>? capturedQueryParams;

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((invocation) async {
        capturedQueryParams = invocation.namedArguments[const Symbol('queryParameters')]
            as Map<String, dynamic>?;
        return Response(
          requestOptions: RequestOptions(path: '/v1/charities'),
          statusCode: 200,
          data: {
            'data': {'nonprofits': [], 'total': 0},
          },
        );
      });

      final repo = CommitmentContractsRepository(mockClient);
      await repo.searchCharities(category: 'Health');

      expect(capturedQueryParams, isNotNull);
      expect(capturedQueryParams!['category'], equals('Health'));
    });
  });

  // ── getDefaultCharity ─────────────────────────────────────────────────────

  group('CommitmentContractsRepository.getDefaultCharity (Story 6.3)', () {
    test('fires GET /v1/charities/default and maps charityId + charityName', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/charities/default';

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'charityId': 'american-red-cross',
              'charityName': 'American Red Cross',
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getDefaultCharity();

      final captured =
          verify(() => mockDio.get<Map<String, dynamic>>(captureAny())).captured;
      expect(captured.single, equals(expectedPath));
      expect(result.charityId, equals('american-red-cross'));
      expect(result.charityName, equals('American Red Cross'));
    });

    test('maps charityId and charityName as null when no default set', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/charities/default'),
          statusCode: 200,
          data: {
            'data': {'charityId': null, 'charityName': null},
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getDefaultCharity();

      expect(result.charityId, isNull);
      expect(result.charityName, isNull);
    });
  });

  // ── setDefaultCharity ─────────────────────────────────────────────────────

  group('CommitmentContractsRepository.setDefaultCharity (Story 6.3)', () {
    test(
        "fires PUT /v1/charities/default with correct body for 'American Red Cross'",
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/charities/default';
      Map<String, dynamic>? capturedBody;

      when(
        () => mockDio.put<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'charityId': 'american-red-cross',
              'charityName': 'American Red Cross',
            },
          },
        );
      });

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.setDefaultCharity(
        'american-red-cross',
        'American Red Cross',
      );

      final captured = verify(
        () => mockDio.put<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));
      expect(capturedBody, isNotNull);
      expect(capturedBody!['charityId'], equals('american-red-cross'));
      expect(capturedBody!['charityName'], equals('American Red Cross'));
      expect(result.charityId, equals('american-red-cross'));
      expect(result.charityName, equals('American Red Cross'));
    });
  });
}
