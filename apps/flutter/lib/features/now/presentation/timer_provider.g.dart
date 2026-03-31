// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier that manages the task timer state.
///
/// Uses `keepAlive: true` so the timer survives tab switches.
/// The 1-second [Timer.periodic] is ONLY for display updates — the
/// authoritative elapsed time is always `elapsedSeconds + (now - startedAt)`.

@ProviderFor(TaskTimer)
final taskTimerProvider = TaskTimerProvider._();

/// Riverpod notifier that manages the task timer state.
///
/// Uses `keepAlive: true` so the timer survives tab switches.
/// The 1-second [Timer.periodic] is ONLY for display updates — the
/// authoritative elapsed time is always `elapsedSeconds + (now - startedAt)`.
final class TaskTimerProvider extends $NotifierProvider<TaskTimer, TimerState> {
  /// Riverpod notifier that manages the task timer state.
  ///
  /// Uses `keepAlive: true` so the timer survives tab switches.
  /// The 1-second [Timer.periodic] is ONLY for display updates — the
  /// authoritative elapsed time is always `elapsedSeconds + (now - startedAt)`.
  TaskTimerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskTimerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskTimerHash();

  @$internal
  @override
  TaskTimer create() => TaskTimer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimerState>(value),
    );
  }
}

String _$taskTimerHash() => r'bd0fd5cd5aca3f501247d6aa9b8df7da0abeb07c';

/// Riverpod notifier that manages the task timer state.
///
/// Uses `keepAlive: true` so the timer survives tab switches.
/// The 1-second [Timer.periodic] is ONLY for display updates — the
/// authoritative elapsed time is always `elapsedSeconds + (now - startedAt)`.

abstract class _$TaskTimer extends $Notifier<TimerState> {
  TimerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TimerState, TimerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimerState, TimerState>,
              TimerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
