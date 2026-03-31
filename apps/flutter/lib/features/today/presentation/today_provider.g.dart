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
