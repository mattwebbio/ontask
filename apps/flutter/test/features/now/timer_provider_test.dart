import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/now/data/now_repository.dart';
import 'package:ontask/features/now/domain/now_task.dart';
import 'package:ontask/features/now/presentation/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeNowRepository extends NowRepository {
  int startCallCount = 0;
  int pauseCallCount = 0;
  int stopCallCount = 0;
  String? lastTaskId;

  _FakeNowRepository()
      : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<NowTask?> getCurrentTask() async => null;

  @override
  Future<NowTask> startTask(String id) async {
    startCallCount++;
    lastTaskId = id;
    return _stubTask(id, startedAt: DateTime.now());
  }

  @override
  Future<NowTask> pauseTask(String id) async {
    pauseCallCount++;
    lastTaskId = id;
    return _stubTask(id, elapsedSeconds: 120);
  }

  @override
  Future<NowTask> stopTask(String id) async {
    stopCallCount++;
    lastTaskId = id;
    return _stubTask(id, elapsedSeconds: 300);
  }

  NowTask _stubTask(String id, {DateTime? startedAt, int? elapsedSeconds}) {
    return NowTask(
      id: id,
      title: 'Test task',
      startedAt: startedAt,
      elapsedSeconds: elapsedSeconds,
      createdAt: DateTime(2026, 3, 30),
      updatedAt: DateTime(2026, 3, 30),
    );
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskTimer', () {
    late ProviderContainer container;
    late _FakeNowRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeNowRepository();
      container = ProviderContainer(overrides: [
        nowRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
    });

    tearDown(() => container.dispose());

    test('initial state is idle', () {
      final state = container.read(taskTimerProvider);
      expect(state.isRunning, false);
      expect(state.elapsedSeconds, 0);
      expect(state.startedAt, isNull);
    });

    test('startTimer sets isRunning = true and startedAt', () {
      container.read(taskTimerProvider.notifier).startTimer('task-1');
      final state = container.read(taskTimerProvider);
      expect(state.isRunning, true);
      expect(state.startedAt, isNotNull);
    });

    test('pauseTimer stops timer and accumulates elapsedSeconds', () async {
      final notifier = container.read(taskTimerProvider.notifier);
      notifier.startTimer('task-1');

      // Wait a tiny bit for elapsed computation to work
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.pauseTimer('task-1');

      final state = container.read(taskTimerProvider);
      expect(state.isRunning, false);
      expect(state.startedAt, isNull);
      expect(state.elapsedSeconds, greaterThanOrEqualTo(0));
      expect(fakeRepo.pauseCallCount, 1);
    });

    test('stopTimer stops timer and accumulates elapsedSeconds', () async {
      final notifier = container.read(taskTimerProvider.notifier);
      notifier.startTimer('task-1');

      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.stopTimer('task-1');

      final state = container.read(taskTimerProvider);
      expect(state.isRunning, false);
      expect(state.startedAt, isNull);
      expect(state.elapsedSeconds, greaterThanOrEqualTo(0));
      expect(fakeRepo.stopCallCount, 1);
    });

    test('toggleTimer alternates between start and pause', () async {
      final notifier = container.read(taskTimerProvider.notifier);

      // First toggle: starts
      await notifier.toggleTimer('task-1');
      expect(container.read(taskTimerProvider).isRunning, true);
      expect(fakeRepo.startCallCount, 1);

      // Second toggle: pauses
      await notifier.toggleTimer('task-1');
      expect(container.read(taskTimerProvider).isRunning, false);
      expect(fakeRepo.pauseCallCount, 1);
    });

    test('auto-resume with existing startedAt', () {
      final pastStart = DateTime.now().subtract(const Duration(minutes: 5));
      container.read(taskTimerProvider.notifier).startTimer(
            'task-1',
            existingStartedAt: pastStart,
            existingElapsed: 100,
          );

      final state = container.read(taskTimerProvider);
      expect(state.isRunning, true);
      expect(state.startedAt, pastStart);
      expect(state.elapsedSeconds, 100);
    });

    test('elapsed computation: storedElapsed + (now - startedAt)', () {
      final pastStart = DateTime.now().subtract(const Duration(seconds: 30));
      container.read(taskTimerProvider.notifier).startTimer(
            'task-1',
            existingStartedAt: pastStart,
            existingElapsed: 100,
          );

      final elapsed =
          container.read(taskTimerProvider.notifier).currentElapsed;
      // Should be approximately 130 (100 stored + 30 delta)
      expect(elapsed, greaterThanOrEqualTo(129));
      expect(elapsed, lessThanOrEqualTo(132));
    });

    test('startTimer records existingElapsed correctly', () {
      container.read(taskTimerProvider.notifier).startTimer(
            'task-1',
            existingElapsed: 500,
          );

      final state = container.read(taskTimerProvider);
      expect(state.elapsedSeconds, 500);
      expect(state.isRunning, true);
    });

    test('multiple pause/resume cycles accumulate correctly', () async {
      final notifier = container.read(taskTimerProvider.notifier);

      // Start with some existing time
      notifier.startTimer('task-1', existingElapsed: 100);

      // Pause
      await notifier.pauseTimer('task-1');
      final afterPause = container.read(taskTimerProvider);
      expect(afterPause.isRunning, false);
      expect(afterPause.elapsedSeconds, greaterThanOrEqualTo(100));

      // Restart
      notifier.startTimer(
        'task-1',
        existingElapsed: afterPause.elapsedSeconds,
      );
      expect(container.read(taskTimerProvider).isRunning, true);
    });
  });
}
