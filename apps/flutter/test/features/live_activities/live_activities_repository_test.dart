import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:live_activities/live_activities.dart';

import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/live_activities/data/live_activities_repository.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockLiveActivities extends Mock implements LiveActivities {}

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a [LiveActivitiesRepository] with an injected mock plugin.
/// The ApiClient is also mocked so registerToken network calls no-op.
LiveActivitiesRepository _makeRepo(
  MockLiveActivities mockPlugin,
  MockApiClient mockApiClient,
) {
  return LiveActivitiesRepository(
    apiClient: mockApiClient,
    plugin: mockPlugin,
  );
}

/// Stubs out the ApiClient.dio.post so that registerToken calls succeed silently.
void _stubApiClientNoOp(MockApiClient mockApiClient, MockDio mockDio) {
  when(() => mockApiClient.dio).thenReturn(mockDio);
  when(() => mockDio.post<void>(any(), data: any(named: 'data')))
      .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLiveActivities mockPlugin;
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late LiveActivitiesRepository repo;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockPlugin = MockLiveActivities();
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    repo = _makeRepo(mockPlugin, mockApiClient);
    _stubApiClientNoOp(mockApiClient, mockDio);
  });

  tearDown(() {
    // Always reset platform override after each test.
    debugDefaultTargetPlatformOverride = null;
  });

  // ── startTaskTimerActivity ─────────────────────────────────────────────────

  group('startTaskTimerActivity', () {
    test('returns null on non-iOS platform without calling plugin', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final result = await repo.startTaskTimerActivity(
        taskId: 'task-1',
        taskTitle: 'Write tests',
      );

      expect(result, isNull);
      verifyNever(() => mockPlugin.createActivity(any()));
    });

    test('calls createActivity with correct data map on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      const fakeActivityId = 'activity-abc-123';
      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => fakeActivityId);

      final result = await repo.startTaskTimerActivity(
        taskId: 'task-1',
        taskTitle: 'Write tests',
        elapsedSeconds: 30,
        stakeAmount: 10.0,
      );

      expect(result, equals(fakeActivityId));

      final captured = verify(() => mockPlugin.createActivity(captureAny()))
          .captured
          .first as Map<String, dynamic>;

      expect(captured['taskTitle'], equals('Write tests'));
      expect(captured['elapsedSeconds'], equals(30));
      expect(captured['deadlineTimestamp'], isNull);
      expect(captured['stakeAmount'], equals(10.0));
      expect(captured['activityStatus'], equals('active'));
    });

    test('passes elapsedSeconds = 0 by default on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => 'activity-xyz');

      await repo.startTaskTimerActivity(
        taskId: 'task-2',
        taskTitle: 'Default elapsed',
      );

      final captured = verify(() => mockPlugin.createActivity(captureAny()))
          .captured
          .first as Map<String, dynamic>;

      expect(captured['elapsedSeconds'], equals(0));
    });
  });

  // ── startCommitmentCountdownActivity ──────────────────────────────────────

  group('startCommitmentCountdownActivity', () {
    test('returns null on non-iOS platform without calling plugin', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final result = await repo.startCommitmentCountdownActivity(
        taskId: 'task-1',
        taskTitle: 'Finish report',
        deadlineTimestamp: DateTime(2026, 4, 2, 18, 0),
      );

      expect(result, isNull);
      verifyNever(() => mockPlugin.createActivity(any()));
    });

    test('calls createActivity with elapsedSeconds=null and ISO deadline on iOS',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      const fakeActivityId = 'countdown-abc-456';
      final deadline = DateTime(2026, 4, 2, 18, 0);
      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => fakeActivityId);

      final result = await repo.startCommitmentCountdownActivity(
        taskId: 'task-1',
        taskTitle: 'Finish report',
        deadlineTimestamp: deadline,
        stakeAmount: 25.0,
      );

      expect(result, equals(fakeActivityId));

      final captured = verify(() => mockPlugin.createActivity(captureAny()))
          .captured
          .first as Map<String, dynamic>;

      expect(captured['elapsedSeconds'], isNull);
      expect(captured['deadlineTimestamp'], equals(deadline.toIso8601String()));
      expect(captured['stakeAmount'], equals(25.0));
      expect(captured['activityStatus'], equals('active'));
    });
  });

  // ── updateElapsedSeconds ──────────────────────────────────────────────────

  group('updateElapsedSeconds', () {
    test('returns without calling plugin on non-iOS platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await repo.updateElapsedSeconds(
        activityId: 'activity-1',
        elapsedSeconds: 120,
      );

      verifyNever(() => mockPlugin.updateActivity(any(), any()));
    });

    test('calls updateActivity with correct activityId and elapsed on iOS',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      when(() => mockPlugin.updateActivity(any(), any()))
          .thenAnswer((_) async {});

      await repo.updateElapsedSeconds(
        activityId: 'activity-1',
        elapsedSeconds: 120,
      );

      final args =
          verify(() => mockPlugin.updateActivity(captureAny(), captureAny()))
              .captured;

      expect(args[0], equals('activity-1'));
      expect(
        (args[1] as Map<String, dynamic>)['elapsedSeconds'],
        equals(120),
      );
    });
  });

  // ── endActivity ───────────────────────────────────────────────────────────

  group('endActivity', () {
    test('returns without calling plugin on non-iOS platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await repo.endActivity(activityId: 'activity-1');

      verifyNever(() => mockPlugin.endActivity(any()));
    });

    test('calls endActivity with correct activityId on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      when(() => mockPlugin.endActivity(any())).thenAnswer((_) async {});

      await repo.endActivity(activityId: 'activity-end-789');

      verify(() => mockPlugin.endActivity('activity-end-789')).called(1);
    });
  });

  // ── startWatchModeActivity ─────────────────────────────────────────────────

  group('startWatchModeActivity', () {
    test('returns null on non-iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final result = await repo.startWatchModeActivity(
        taskId: 'task-1',
        taskTitle: 'Write report',
      );
      expect(result, isNull);
      verifyNever(() => mockPlugin.createActivity(any()));
      debugDefaultTargetPlatformOverride = null;
    });

    test('calls createActivity with watchMode activityStatus on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _stubApiClientNoOp(mockApiClient, mockDio);
      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => 'activity-watch-1');

      final result = await repo.startWatchModeActivity(
        taskId: 'task-1',
        taskTitle: 'Write report',
      );

      expect(result, equals('activity-watch-1'));
      final captured = verify(() => mockPlugin.createActivity(captureAny())).captured;
      final data = captured.first as Map<String, dynamic>;
      expect(data['activityStatus'], equals('watchMode'));
      expect(data['elapsedSeconds'], equals(0));
      expect(data['taskTitle'], equals('Write report'));
      debugDefaultTargetPlatformOverride = null;
    });

    test('passes deadlineTimestamp as ISO 8601 string when provided', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _stubApiClientNoOp(mockApiClient, mockDio);
      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => 'activity-watch-2');
      final deadline = DateTime(2026, 5, 1, 14, 0, 0);

      await repo.startWatchModeActivity(
        taskId: 'task-2',
        taskTitle: 'Study session',
        deadlineTimestamp: deadline,
      );

      final captured = verify(() => mockPlugin.createActivity(captureAny())).captured;
      final data = captured.first as Map<String, dynamic>;
      expect(data['deadlineTimestamp'], equals(deadline.toIso8601String()));
      debugDefaultTargetPlatformOverride = null;
    });

    test('passes null deadlineTimestamp when not provided', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _stubApiClientNoOp(mockApiClient, mockDio);
      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => 'activity-watch-3');

      await repo.startWatchModeActivity(
        taskId: 'task-3',
        taskTitle: 'Focus work',
      );

      final captured = verify(() => mockPlugin.createActivity(captureAny())).captured;
      final data = captured.first as Map<String, dynamic>;
      expect(data['deadlineTimestamp'], isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    test('registers token with watchMode activityType after createActivity', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _stubApiClientNoOp(mockApiClient, mockDio);
      when(() => mockPlugin.createActivity(any()))
          .thenAnswer((_) async => 'activity-watch-4');

      await repo.startWatchModeActivity(
        taskId: 'task-4',
        taskTitle: 'Deep work',
      );

      verify(
        () => mockDio.post<void>(
          '/v1/live-activities/token',
          data: any(
            named: 'data',
            that: predicate<Map<String, dynamic>>(
              (d) => d['activityType'] == 'watch_mode',
            ),
          ),
        ),
      ).called(1);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  // ── Platform guard — all methods ──────────────────────────────────────────

  group('Platform guards', () {
    test('all methods return early without error on macOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      await expectLater(
        repo.startTaskTimerActivity(taskId: 't', taskTitle: 'Task'),
        completion(isNull),
      );
      await expectLater(
        repo.startCommitmentCountdownActivity(
          taskId: 't',
          taskTitle: 'Task',
          deadlineTimestamp: DateTime.now().add(const Duration(hours: 1)),
        ),
        completion(isNull),
      );
      await expectLater(
        repo.startWatchModeActivity(taskId: 't', taskTitle: 'Task'),
        completion(isNull),
      );
      await expectLater(
        repo.updateElapsedSeconds(activityId: 'a', elapsedSeconds: 0),
        completes,
      );
      await expectLater(
        repo.endActivity(activityId: 'a'),
        completes,
      );

      verifyNever(() => mockPlugin.createActivity(any()));
      verifyNever(() => mockPlugin.updateActivity(any(), any()));
      verifyNever(() => mockPlugin.endActivity(any()));
    });
  });
}
