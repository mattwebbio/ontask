// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AsyncNotifier that manages the list of tasks for the Today tab.
///
/// Loads tasks via [TodayRepository.getTodayTasks] and supports
/// completing and rescheduling tasks in-place.

@ProviderFor(Today)
final todayProvider = TodayProvider._();

/// AsyncNotifier that manages the list of tasks for the Today tab.
///
/// Loads tasks via [TodayRepository.getTodayTasks] and supports
/// completing and rescheduling tasks in-place.
final class TodayProvider extends $AsyncNotifierProvider<Today, List<Task>> {
  /// AsyncNotifier that manages the list of tasks for the Today tab.
  ///
  /// Loads tasks via [TodayRepository.getTodayTasks] and supports
  /// completing and rescheduling tasks in-place.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  Today create() => Today();
}

String _$todayHash() => r'3935e97afdf5ea3e5edcbfa362acffd295a02fc1';

/// AsyncNotifier that manages the list of tasks for the Today tab.
///
/// Loads tasks via [TodayRepository.getTodayTasks] and supports
/// completing and rescheduling tasks in-place.

abstract class _$Today extends $AsyncNotifier<List<Task>> {
  FutureOr<List<Task>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Task>>, List<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Task>>, List<Task>>,
              AsyncValue<List<Task>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// AsyncNotifier for calendar events displayed in the Today tab timeline.
///
/// Loads events via [TodayRepository.getCalendarEvents] for today's window.
/// Returns an empty list on failure — calendar events are optional; they
/// must never cause the Today tab to fail to load.

@ProviderFor(TodayCalendarEvents)
final todayCalendarEventsProvider = TodayCalendarEventsProvider._();

/// AsyncNotifier for calendar events displayed in the Today tab timeline.
///
/// Loads events via [TodayRepository.getCalendarEvents] for today's window.
/// Returns an empty list on failure — calendar events are optional; they
/// must never cause the Today tab to fail to load.
final class TodayCalendarEventsProvider
    extends
        $AsyncNotifierProvider<TodayCalendarEvents, List<CalendarEventDto>> {
  /// AsyncNotifier for calendar events displayed in the Today tab timeline.
  ///
  /// Loads events via [TodayRepository.getCalendarEvents] for today's window.
  /// Returns an empty list on failure — calendar events are optional; they
  /// must never cause the Today tab to fail to load.
  TodayCalendarEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayCalendarEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayCalendarEventsHash();

  @$internal
  @override
  TodayCalendarEvents create() => TodayCalendarEvents();
}

String _$todayCalendarEventsHash() =>
    r'c1588bb737224ffb282e7fb1c038312f4277e151';

/// AsyncNotifier for calendar events displayed in the Today tab timeline.
///
/// Loads events via [TodayRepository.getCalendarEvents] for today's window.
/// Returns an empty list on failure — calendar events are optional; they
/// must never cause the Today tab to fail to load.

abstract class _$TodayCalendarEvents
    extends $AsyncNotifier<List<CalendarEventDto>> {
  FutureOr<List<CalendarEventDto>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<CalendarEventDto>>, List<CalendarEventDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CalendarEventDto>>,
                List<CalendarEventDto>
              >,
              AsyncValue<List<CalendarEventDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
