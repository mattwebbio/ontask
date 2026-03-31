// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AsyncNotifier that loads the weekly schedule health data.
///
/// Calculates the current week's Monday and loads 7-day health
/// from [TodayRepository.getScheduleHealth].

@ProviderFor(ScheduleHealth)
final scheduleHealthProvider = ScheduleHealthProvider._();

/// AsyncNotifier that loads the weekly schedule health data.
///
/// Calculates the current week's Monday and loads 7-day health
/// from [TodayRepository.getScheduleHealth].
final class ScheduleHealthProvider
    extends $AsyncNotifierProvider<ScheduleHealth, List<DayHealth>> {
  /// AsyncNotifier that loads the weekly schedule health data.
  ///
  /// Calculates the current week's Monday and loads 7-day health
  /// from [TodayRepository.getScheduleHealth].
  ScheduleHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleHealthHash();

  @$internal
  @override
  ScheduleHealth create() => ScheduleHealth();
}

String _$scheduleHealthHash() => r'5d8d586283690aeb24c4c52191c5f0099a99fd29';

/// AsyncNotifier that loads the weekly schedule health data.
///
/// Calculates the current week's Monday and loads 7-day health
/// from [TodayRepository.getScheduleHealth].

abstract class _$ScheduleHealth extends $AsyncNotifier<List<DayHealth>> {
  FutureOr<List<DayHealth>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<DayHealth>>, List<DayHealth>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DayHealth>>, List<DayHealth>>,
              AsyncValue<List<DayHealth>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
