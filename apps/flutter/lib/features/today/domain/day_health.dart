import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_health_status.dart';

part 'day_health.freezed.dart';

/// Domain model for a single day's schedule health.
///
/// Used by [ScheduleHealthStrip] to display weekly day chips
/// coloured by health status.
@freezed
abstract class DayHealth with _$DayHealth {
  const factory DayHealth({
    required DateTime date,
    required DayHealthStatus status,
    required int taskCount,
    required double capacityPercent,
    required List<String> atRiskTaskIds,
  }) = _DayHealth;
}
