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

  // ── getImpactSummary ──────────────────────────────────────────────────────

  group('CommitmentContractsRepository.getImpactSummary (AC1, AC2)', () {
    test(
        'fires GET /v1/impact and maps totalDonatedCents, commitmentsKept, commitmentsMissed',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/impact';
      final earnedAt = DateTime.utc(2026, 1, 15, 12, 0, 0).toIso8601String();

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: {
            'data': {
              'totalDonatedCents': 2500,
              'commitmentsKept': 3,
              'commitmentsMissed': 1,
              'charityBreakdown': [
                {'charityName': 'American Red Cross', 'donatedCents': 2500},
              ],
              'milestones': [
                {
                  'id': 'first-kept',
                  'title': 'First commitment kept.',
                  'body': 'You showed up when it mattered.',
                  'earnedAt': earnedAt,
                  'shareText':
                      'I kept my first commitment with On Task.',
                },
              ],
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final summary = await repo.getImpactSummary();

      final captured =
          verify(() => mockDio.get<Map<String, dynamic>>(captureAny()))
              .captured;
      expect(captured.single, equals(expectedPath));

      expect(summary.totalDonatedCents, equals(2500));
      expect(summary.commitmentsKept, equals(3));
      expect(summary.commitmentsMissed, equals(1));
    });

    test('maps milestones list with correct id, title, body, earnedAt (as DateTime), shareText',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      final earnedAt = DateTime.utc(2026, 1, 15, 12, 0, 0);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/impact'),
          statusCode: 200,
          data: {
            'data': {
              'totalDonatedCents': 2500,
              'commitmentsKept': 3,
              'commitmentsMissed': 1,
              'charityBreakdown': [],
              'milestones': [
                {
                  'id': 'first-kept',
                  'title': 'First commitment kept.',
                  'body': 'You showed up when it mattered.',
                  'earnedAt': earnedAt.toIso8601String(),
                  'shareText':
                      'I kept my first commitment with On Task.',
                },
              ],
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final summary = await repo.getImpactSummary();

      expect(summary.milestones.length, equals(1));
      final m = summary.milestones.first;
      expect(m.id, equals('first-kept'));
      expect(m.title, equals('First commitment kept.'));
      expect(m.body, equals('You showed up when it mattered.'));
      expect(m.earnedAt, equals(earnedAt));
      expect(m.shareText, equals('I kept my first commitment with On Task.'));
    });

    test('maps charityBreakdown list with correct charityName and donatedCents',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      final earnedAt = DateTime.utc(2026, 1, 15).toIso8601String();

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/impact'),
          statusCode: 200,
          data: {
            'data': {
              'totalDonatedCents': 2500,
              'commitmentsKept': 3,
              'commitmentsMissed': 1,
              'charityBreakdown': [
                {'charityName': 'American Red Cross', 'donatedCents': 2500},
              ],
              'milestones': [
                {
                  'id': 'first-kept',
                  'title': 'First commitment kept.',
                  'body': 'You showed up.',
                  'earnedAt': earnedAt,
                  'shareText': 'Share text.',
                },
              ],
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final summary = await repo.getImpactSummary();

      expect(summary.charityBreakdown.length, equals(1));
      final breakdown = summary.charityBreakdown.first;
      expect(breakdown.charityName, equals('American Red Cross'));
      expect(breakdown.donatedCents, equals(2500));
    });
  });

  // ── getTaskStake with modification window (Story 6.6) ─────────────────────

  group('CommitmentContractsRepository.getTaskStake with modification window (Story 6.6)', () {
    test('maps stakeModificationDeadline as DateTime when stake is active', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/tasks/task-id/stake';
      final deadlineUtc = DateTime.utc(2026, 4, 3, 15, 0, 0);
      final deadlineIso = deadlineUtc.toIso8601String();

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
              'stakeModificationDeadline': deadlineIso,
              'canModify': true,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getTaskStake('task-id');

      expect(result.stakeAmountCents, equals(2500));
      expect(result.stakeModificationDeadline, isNotNull);
      expect(result.canModify, isTrue);
    });

    test('sets canModify = false and stakeModificationDeadline = null when no stake', () async {
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
              'stakeModificationDeadline': null,
              'canModify': false,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getTaskStake('task-id');

      expect(result.stakeAmountCents, isNull);
      expect(result.stakeModificationDeadline, isNull);
      expect(result.canModify, isFalse);
    });

    test('sets canModify = false when deadline is in the past (window closed)', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      // Deadline 1 hour ago
      final pastDeadline = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final pastDeadlineIso = pastDeadline.toIso8601String();

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/tasks/task-id/stake'),
          statusCode: 200,
          data: {
            'data': {
              'taskId': 'task-id',
              'stakeAmountCents': 2500,
              'stakeModificationDeadline': pastDeadlineIso,
              'canModify': false,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getTaskStake('task-id');

      expect(result.canModify, isFalse);
      expect(result.stakeModificationDeadline, isNotNull);
    });
  });

  // ── cancelStake (Story 6.6) ───────────────────────────────────────────────

  group('CommitmentContractsRepository.cancelStake (Story 6.6)', () {
    test("cancelStake('task-id') fires POST /v1/tasks/task-id/stake/cancel with empty body", () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      const expectedPath = '/v1/tasks/task-id/stake/cancel';
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
            'data': {'cancelled': true},
          },
        );
      });

      final repo = CommitmentContractsRepository(mockClient);
      await repo.cancelStake('task-id');

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: any(named: 'data'),
        ),
      ).captured;
      expect(captured.single, equals(expectedPath));
      expect(capturedBody, isEmpty);
    });

    test('cancelStake propagates DioException with 422 STAKE_LOCKED when window closed', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/tasks/task-id/stake/cancel'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/tasks/task-id/stake/cancel'),
            statusCode: 422,
            data: {
              'error': {
                'code': 'STAKE_LOCKED',
                'message': 'Stake is locked — the deadline is too close to change it',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);

      await expectLater(
        () => repo.cancelStake('task-id'),
        throwsA(isA<DioException>()),
      );
    });

    test('cancelStake propagates DioException with 422 NO_ACTIVE_STAKE when no stake', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/tasks/task-id/stake/cancel'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/tasks/task-id/stake/cancel'),
            statusCode: 422,
            data: {
              'error': {
                'code': 'NO_ACTIVE_STAKE',
                'message': 'No active stake on this task',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);

      await expectLater(
        () => repo.cancelStake('task-id'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── CommitmentContractsRepository — group commitments (Story 6.7) ──────────

  group('CommitmentContractsRepository — group commitments (Story 6.7)', () {
    const stubGroupCommitmentId = '00000000-0000-0000-0000-000000000001';
    const stubListId = '00000000-0000-0000-0000-000000000002';
    const stubTaskId = '00000000-0000-0000-0000-000000000003';
    const stubUserId = '00000000-0000-0000-0000-000000000099';
    const stubNow = '2026-04-01T00:00:00.000Z';

    Map<String, dynamic> stubGroupCommitmentResponse({
      String status = 'pending',
      List<Map<String, dynamic>> members = const [],
    }) {
      return {
        'data': {
          'id': stubGroupCommitmentId,
          'listId': stubListId,
          'taskId': stubTaskId,
          'proposedByUserId': stubUserId,
          'status': status,
          'members': members,
          'createdAt': stubNow,
          'updatedAt': stubNow,
        },
      };
    }

    test('proposeGroupCommitment sends POST with correct body', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/group-commitments'),
          statusCode: 201,
          data: stubGroupCommitmentResponse(),
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.proposeGroupCommitment(
        listId: stubListId,
        taskId: stubTaskId,
      );

      final capturedArgs = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(capturedArgs[0], equals('/v1/group-commitments'));
      expect(
        capturedArgs[1],
        equals({'listId': stubListId, 'taskId': stubTaskId}),
      );
      expect(result.status, equals('pending'));
      expect(result.listId, equals(stubListId));
      expect(result.taskId, equals(stubTaskId));
    });

    test('getGroupCommitment fires GET and maps response', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/group-commitments/$stubGroupCommitmentId',
          ),
          statusCode: 200,
          data: stubGroupCommitmentResponse(),
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getGroupCommitment(stubGroupCommitmentId);

      final captured = verify(
        () => mockDio.get<Map<String, dynamic>>(captureAny()),
      ).captured;

      expect(
        captured.single,
        equals('/v1/group-commitments/$stubGroupCommitmentId'),
      );
      expect(result.id, equals(stubGroupCommitmentId));
    });

    test('approveGroupCommitment fires POST with stakeAmountCents', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/group-commitments/$stubGroupCommitmentId/approve',
          ),
          statusCode: 200,
          data: stubGroupCommitmentResponse(
            members: [
              {
                'userId': stubUserId,
                'stakeAmountCents': 1500,
                'approved': true,
                'poolModeOptIn': false,
              },
            ],
          ),
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.approveGroupCommitment(
        stubGroupCommitmentId,
        stakeAmountCents: 1500,
      );

      final capturedArgs = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(
        capturedArgs[0],
        equals('/v1/group-commitments/$stubGroupCommitmentId/approve'),
      );
      expect(capturedArgs[1], equals({'stakeAmountCents': 1500}));
      expect(result.members.first.approved, isTrue);
      expect(result.members.first.stakeAmountCents, equals(1500));
    });

    test('setPoolModeOptIn fires POST with optIn: true', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/v1/group-commitments/$stubGroupCommitmentId/pool-mode',
          ),
          statusCode: 200,
          data: {
            'data': {
              'groupCommitmentId': stubGroupCommitmentId,
              'userId': stubUserId,
              'poolModeOptIn': true,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      await repo.setPoolModeOptIn(stubGroupCommitmentId, optIn: true);

      final capturedArgs = verify(
        () => mockDio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(
        capturedArgs[0],
        equals('/v1/group-commitments/$stubGroupCommitmentId/pool-mode'),
      );
      expect(capturedArgs[1], equals({'optIn': true}));
    });

    test(
        '_groupCommitmentFromJson maps stakeAmountCents correctly using (x as num).toInt()',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      // API may return stakeAmountCents as a double (e.g. 1500.0) — must cast via num
      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/group-commitments/x'),
          statusCode: 200,
          data: {
            'data': {
              'id': stubGroupCommitmentId,
              'listId': stubListId,
              'taskId': stubTaskId,
              'proposedByUserId': stubUserId,
              'status': 'pending',
              'members': [
                {
                  'userId': stubUserId,
                  'stakeAmountCents': 2500.0, // returned as double from JSON
                  'approved': false,
                  'poolModeOptIn': false,
                },
              ],
              'createdAt': stubNow,
              'updatedAt': stubNow,
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getGroupCommitment(stubGroupCommitmentId);

      expect(result.members.first.stakeAmountCents, equals(2500));
      expect(result.members.first.stakeAmountCents, isA<int>());
    });

    test('_groupCommitmentFromJson handles empty members list', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/group-commitments/x'),
          statusCode: 200,
          data: stubGroupCommitmentResponse(members: []),
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final result = await repo.getGroupCommitment(stubGroupCommitmentId);

      expect(result.members, isEmpty);
    });
  });

  // ── getBillingHistory (AC1, Story 6.9) ────────────────────────────────────

  group('CommitmentContractsRepository.getBillingHistory (AC1)', () {
    test('fires GET /v1/billing-history', () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/billing-history'),
          statusCode: 200,
          data: {
            'data': {
              'entries': [],
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      await repo.getBillingHistory();

      final captured =
          verify(() => mockDio.get<Map<String, dynamic>>(captureAny()))
              .captured;
      expect(captured.single, equals('/v1/billing-history'));
    });

    test('maps charged entry (amountCents via .toInt(), date via DateTime.parse, charityName)',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/billing-history'),
          statusCode: 200,
          data: {
            'data': {
              'entries': [
                {
                  'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
                  'taskName': 'Complete quarterly report',
                  'date': '2026-03-15T10:00:00.000Z',
                  'amountCents': 5000,
                  'disbursementStatus': 'completed',
                  'charityName': 'American Red Cross',
                },
              ],
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final entries = await repo.getBillingHistory();

      expect(entries.length, equals(1));
      final entry = entries.first;
      expect(entry.taskName, equals('Complete quarterly report'));
      expect(entry.amountCents, equals(5000));
      expect(entry.disbursementStatus, equals('completed'));
      expect(entry.charityName, equals('American Red Cross'));
      expect(entry.date, isA<DateTime>());
    });

    test('maps cancelled entry with amountCents == null, disbursementStatus "cancelled"',
        () async {
      final mockDio = MockDio();
      final mockClient = MockApiClient();
      when(() => mockClient.dio).thenReturn(mockDio);

      when(
        () => mockDio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/billing-history'),
          statusCode: 200,
          data: {
            'data': {
              'entries': [
                {
                  'id': 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
                  'taskName': 'Read three chapters',
                  'date': '2026-03-25T09:00:00.000Z',
                  'amountCents': null,
                  'disbursementStatus': 'cancelled',
                  'charityName': null,
                },
              ],
            },
          },
        ),
      );

      final repo = CommitmentContractsRepository(mockClient);
      final entries = await repo.getBillingHistory();

      expect(entries.length, equals(1));
      final entry = entries.first;
      expect(entry.amountCents, isNull);
      expect(entry.disbursementStatus, equals('cancelled'));
      expect(entry.charityName, isNull);
    });
  });
}
