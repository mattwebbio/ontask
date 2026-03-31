import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/now_repository.dart';

part 'timer_provider.freezed.dart';
part 'timer_provider.g.dart';

/// Immutable state for the task timer.
@freezed
abstract class TimerState with _$TimerState {
  const factory TimerState({
    DateTime? startedAt,
    @Default(0) int elapsedSeconds,
    @Default(false) bool isRunning,
  }) = _TimerState;
}

/// Riverpod notifier that manages the task timer state.
///
/// Uses `keepAlive: true` so the timer survives tab switches.
/// The 1-second [Timer.periodic] is ONLY for display updates — the
/// authoritative elapsed time is always `elapsedSeconds + (now - startedAt)`.
@Riverpod(keepAlive: true)
class TaskTimer extends _$TaskTimer {
  Timer? _displayTimer;

  @override
  TimerState build() {
    ref.onDispose(() {
      _displayTimer?.cancel();
    });
    return const TimerState();
  }

  /// Computes the current elapsed seconds from stored state + live delta.
  int _computeElapsed(TimerState s) {
    if (s.startedAt == null) return s.elapsedSeconds;
    final delta = DateTime.now().difference(s.startedAt!).inSeconds;
    return s.elapsedSeconds + delta;
  }

  /// Returns the current authoritative elapsed seconds.
  int get currentElapsed => _computeElapsed(state);

  /// Starts the timer for a task.
  ///
  /// If [existingStartedAt] is provided, resumes from that timestamp
  /// (e.g., after app foreground). Otherwise starts from now.
  void startTimer(
    String taskId, {
    DateTime? existingStartedAt,
    int existingElapsed = 0,
  }) {
    final startTime = existingStartedAt ?? DateTime.now();
    state = TimerState(
      startedAt: startTime,
      elapsedSeconds: existingElapsed,
      isRunning: true,
    );
    _startDisplayTimer();

    // TODO(impl): emit 'task_started' event for notification system (Epic 8)
  }

  /// Pauses the timer for a task. Calls the pause API endpoint.
  Future<void> pauseTimer(String taskId) async {
    final elapsed = _computeElapsed(state);
    _displayTimer?.cancel();
    state = TimerState(
      startedAt: null,
      elapsedSeconds: elapsed,
      isRunning: false,
    );

    final repo = ref.read(nowRepositoryProvider);
    await repo.pauseTask(taskId);
  }

  /// Stops the timer for a task. Calls the stop API endpoint.
  /// Stop does NOT mark the task as complete.
  Future<void> stopTimer(String taskId) async {
    final elapsed = _computeElapsed(state);
    _displayTimer?.cancel();
    state = TimerState(
      startedAt: null,
      elapsedSeconds: elapsed,
      isRunning: false,
    );

    final repo = ref.read(nowRepositoryProvider);
    await repo.stopTask(taskId);
  }

  /// Toggles between start and pause (used by Space bar shortcut).
  Future<void> toggleTimer(String taskId) async {
    if (state.isRunning) {
      await pauseTimer(taskId);
    } else {
      startTimer(taskId);
      // Also call the start API
      final repo = ref.read(nowRepositoryProvider);
      await repo.startTask(taskId);
    }
  }

  /// Starts the 1-second periodic timer for display updates only.
  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        // Trigger a state rebuild with updated elapsed display
        if (state.isRunning) {
          state = state.copyWith(
            elapsedSeconds: state.elapsedSeconds,
          );
        }
      },
    );
  }
}
